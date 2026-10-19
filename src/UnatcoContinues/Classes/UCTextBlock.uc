//=============================================================================
// UCTextBlock - un testo scritto nell'editor delle mappe che i computer del gioco leggono:
// la lista delle email di un account, un'email, la lista dei bollettini di un terminale
// pubblico, un bollettino. I computer leggono testi "ExtString" da un pacchetto di testi
// (Computers.TextPackage); UCCampaign, quando la mappa parte, crea per ogni blocco l'ExtString
// <TextName> nel pacchetto UnatcoContinues, e l'editor mette TextPackage=UnatcoContinues
// nei computer che hanno email o bollettini suoi.
// Il testo e' nel formato dei testi del gioco: <EMAIL=nome,oggetto,da,a,cc> per righe della
// lista delle email, <FILE=nome,titolo> per quella dei bollettini, <P> per i paragrafi.
//=============================================================================
class UCTextBlock extends Info;

var() name TextName;
var() string Text;
// Continuations keep long books below the native T3D line limit.
var() string TextMore[64];

static function bool RegisterText(UCTextBlock block)
{
     local ExtString s;
     local int i;

     if (block == None || block.TextName == '') return False;
     s = new(class'UCTextBlock'.Outer, block.TextName) class'ExtString';
     if (s == None) return False;
     s.SetText(block.Text);
     for (i = 0; i < ArrayCount(block.TextMore); i++)
          if (block.TextMore[i] != "") s.AppendText(block.TextMore[i]);
     return True;
}

// The text of a book, datacube or newspaper where the game's own text parser reads it: an ExtString named
// like the object in this package, then its textTag and TextPackage. The original Deus Ex has no SpecialText
// (Revision's free text of an object): its objects of the mod show their text this way. |n = a new line.
static function bool UseText(InformationDevices dev, string text)
{
     local ExtString s;
     local string out;
     local int i;

     if (dev == None || text == "") return False;
     while (True)
     {
          i = InStr(text, "|n");
          if (i < 0) break;
          out = out $ Left(text, i) $ "<P>";
          text = Mid(text, i + 2);
     }
     out = out $ text;
     s = new(class'UCTextBlock'.Outer, dev.Name) class'ExtString';
     if (s == None) return False;
     s.SetText(out);
     dev.textTag = dev.Name;
     dev.TextPackage = string(class'UCTextBlock'.Outer.Name);
     return True;
}

defaultproperties
{
     bHidden=True
}
