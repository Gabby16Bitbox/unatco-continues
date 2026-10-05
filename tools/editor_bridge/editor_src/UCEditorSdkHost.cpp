#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <float.h>
#define EDITOR_API __declspec(dllimport)
#include "Editor.h"
#include "FMallocAnsi.h"
#include "FFileManagerWindows.h"
#include "FConfigCacheIni.h"
#include "FOutputDeviceFile.h"
#include "FOutputDeviceAnsiError.h"
#include "FFeedbackContextAnsi.h"

static void printUtf8(const TCHAR* text, FILE* stream) {
    char buffer[16384];
    int count = WideCharToMultiByte(CP_UTF8, 0, (const WCHAR*)text, -1,
        buffer, sizeof(buffer), NULL, NULL);
    if (count) fwrite(buffer, 1, count - 1, stream);
    fputc('\n', stream); fflush(stream);
}
class Utf8Log : public FOutputDevice {
public:
    void Serialize(const TCHAR* text, EName event) { printUtf8(text, stdout); }
};
class Utf8Feedback : public FFeedbackContextAnsi {
public:
    void Serialize(const TCHAR* text, EName event) { printUtf8(text, stdout); }
};
class Utf8Error : public FOutputDeviceError {
public:
    void Serialize(const TCHAR* text, EName event) { printUtf8(text, stderr); appRequestExit(1); }
    void HandleError() { printUtf8(GErrorHist, stderr); }
};

// Typed bridge operations. They touch one existing mover, never the world BSP.
static int editMover(const char* line) {
    char operation[32], name[128], trailing;
    float x, y, z;
    if (sscanf(line, "UC_MOVER %31s %127s %f %f %f %c", operation, name, &x, &y, &z, &trailing) != 5)
        return 0;
    if (!_finite(x) || !_finite(y) || !_finite(z) || !GEditor->Level) return 0;
    unsigned short wide[128];
    int i;
    for (i=0; name[i]; i++) wide[i] = (unsigned char)name[i];
    wide[i] = 0;
    AMover* mover = NULL;
    for (i=0; i<GEditor->Level->Actors.Num(); i++) {
        AActor* actor = GEditor->Level->Actors(i);
        if (actor && !appStricmp(actor->GetName(), (const TCHAR*)wide)) {
            if (!actor->IsA(AMover::StaticClass())) return 0;
            mover = (AMover*)actor;
            break;
        }
    }
    if (!mover || !mover->Brush || !mover->Brush->Polys) return 0;
    if (!strcmp(operation, "translate")) {
        FVector delta(x,y,z);
        mover->Location += delta;
        mover->BasePos += delta;
        // KeyPos is relative to BasePos. SavedPos contains an editor sentinel;
        // runtime interpolation fields are initialized by Mover.BeginPlay.
    } else if (!strcmp(operation, "scale")) {
        if (x<0.1f || y<0.1f || z<0.1f || x>10 || y>10 || z>10
            || !mover->bDynamicLightMover
            || mover->Brush->LightBits.Num() || mover->Brush->Lights.Num()) return 0;
        for (i=0; i<mover->Brush->Surfs.Num(); i++)
            if (mover->Brush->Surfs(i).iLightMap != INDEX_NONE) return 0;
        // Some Revision movers retain unused LightMap entries even though every
        // surface has INDEX_NONE. Preserve those entries verbatim as well.
        TArray<FLightMapIndex> savedMaps = mover->Brush->LightMap;
        FVector scale(x,y,z);
        FVector inverse(1/x,1/y,1/z);
        // Scale about PrePivot so the world pivot and keyframes stay fixed.
        for (i=0; i<mover->Brush->Polys->Element.Num(); i++) {
            FPoly& poly = mover->Brush->Polys->Element(i);
            for (int k=0; k<poly.NumVertices; k++)
                poly.Vertex[k] = (poly.Vertex[k]-mover->PrePivot)*scale + mover->PrePivot;
            poly.Base = (poly.Base-mover->PrePivot)*scale + mover->PrePivot;
            poly.TextureU = poly.TextureU*inverse;
            poly.TextureV = poly.TextureV*inverse;
            if (poly.CalcNormal()) return 0;
            poly.Base -= poly.Normal * ((poly.Base-poly.Vertex[0]) | poly.Normal);
        }
        GEditor->csgPrepMovingBrush(mover);
        mover->Brush->LightMap = savedMaps;
        mover->Brush->BuildBound();
    } else return 0;
    printf("UCEditorHost|mover|%s|%s|%d\n", name, operation, mover->Brush->Polys->Element.Num());
    return 1;
}

int main(int argc, char** argv) {
    puts("UCEditorHost|initializing SDK"); fflush(stdout);
    if (argc != 2) return 2;
    FILE* input = fopen(argv[1], "rt");
    if (!input) return 3;
    FMallocAnsi malloc;
    Utf8Log log;
    Utf8Error error;
    Utf8Feedback feedback;
    FFileManagerWindows files;
    GIsEditor = 1;
    GIsServer = 1;
    GIsClient = 0;
    puts("UCEditorHost|appInit"); fflush(stdout);
    appInit(TEXT("UCEditorSdkHost"), TEXT("-ini=Revision.ini -nosound"), &malloc,
        &log, &error, &feedback, &files, FConfigCacheIni::Factory, 1);
    GIsStarted = 1;
    puts("UCEditorHost|construct editor"); fflush(stdout);
    GEditor = ConstructObject<UEditorEngine>(UEditorEngine::StaticClass());
    puts("UCEditorHost|initialize editor"); fflush(stdout);
    GEditor->Init();
    puts("UCEditorHost|ready"); fflush(stdout);
    char line[8192];
    while (fgets(line, sizeof(line), input)) {
        line[strcspn(line, "\r\n")] = 0;
        if (!line[0]) continue;
        unsigned short wide[8192];
        int i;
        for (i=0; line[i]; i++) wide[i] = (unsigned char)line[i];
        wide[i] = 0;
        printf("UCEditorHost|command|%s\n", line); fflush(stdout);
        int success = !strncmp(line, "UC_MOVER ", 9) ? editMover(line)
            : GEditor->Exec((const TCHAR*)wide, feedback);
        if (!success) {
            fprintf(stderr, "Unrecognized editor command\n");
            return 4;
        }
        if (GEditor->Level) {
            printf("UCEditorHost|actors|%d\n", GEditor->Level->Actors.Num());
        }
        puts("UCEditorHost|complete"); fflush(stdout);
    }
    fclose(input);
    appPreExit();
    appExit();
    puts("UCEditorHost|done");
    return 0;
}
