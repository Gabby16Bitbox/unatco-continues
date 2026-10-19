// Explicit operation report after authorized entry; attachments retain their source.
class UCSceneSimonsAfterTong extends UCScene;

var bool bTongDead;     // Tong morto prima della fuga
var bool bFired;        // JC ha sparato alla squadra (JCAttackedSpecialProjects)
var int n;
var float d;

function float CallLine(int i)
{
    switch(i)
    {
        case 0:
            if(bTongDead) return Say("WaltonSimons", "Tong's death has been confirmed. The recovery team has secured his facility.");
            return Say("WaltonSimons", "Tong escaped during the operation. The recovery team has secured his facility.");
        case 1:
            if (GetF('UC_VLManifestCopied'))
                return Say("WaltonSimons", "I have reviewed the transfer records you recovered. You will proceed to VersaLife under official authorization.");
            return Say("WaltonSimons", "The recovery team extracted a transfer index from Tong's systems. You will proceed to VersaLife under official authorization.");
        case 2:
            return Say("WaltonSimons", "Verify the shipment identifiers and the Level Two access records. Recover any research Tong's people obtained from their systems. Your clearance will be waiting at reception.");
        case 3: if (!bFired) return 0; return Say("WaltonSimons", "I'm told you fired on Coalition personnel.");
        case 4: if (!bFired) return 0; return Say("WaltonSimons", "We'll discuss your judgment when you return.");
    }
    return -1;
}

function float InfoLine(int i)
{
	return CallLine(i);
}

// Il rapporto esplicito distingue copia di JC ed estrazione di Special Projects.
function UploadEvidence()
{
    local DeusExPlayer P;
    P=Plr(); if (P==None) return;
    SetF('TongEvidenceReportSent',True);
    if (GetF('UC_VLManifestCopied'))
    {
        class'UCSceneTongLab'.static.AddFragment(P);
        P.AddNote("Operation report: independent copy of Tong's transfer index attached. Content and issuing authority still require verification at VersaLife.",False,True);
    }
    else
        P.AddNote("Operation report: no independent field copy attached. Transfer index supplied by Special Projects. Compare this team extraction with the originals at VersaLife.",False,True);
    Msg("Operation report transmitted; attachment provenance recorded.");
}

function NewAssignment()
{
	local DeusExPlayer P;

	P = Plr();
	if (P == None)
		return;
	SetF('MJ12AssaultResolved', True);
	if (P.FindGoal('UCSubmitOperationReport') != None)
		P.GoalCompleted('UCSubmitOperationReport');
	SetF('VersaLifeInvestigationAuthorized', True);
	SetF('SimonsVersaLifeConcern', True);
	if (P.FindGoal('UCSecureTong') != None)
		P.GoalCompleted('UCSecureTong');
	if (P.FindGoal('UCTongArchives') != None)
		P.GoalCompleted('UCTongArchives');
	if (P.FindGoal('UCReportVersaLife') == None)
		P.GoalAdd('UCReportVersaLife', "Walton Simons has authorized an official investigation into the data recovered from Tracer Tong. Compare the Ambrosia shipment identifiers and Special Projects access records with VersaLife's original systems.", True);
	if (!GetF('UC_NoteVersaLifeCode'))
	{
		SetF('UC_NoteVersaLifeCode', True);
		P.AddNote("VersaLife (Wan Chai market, elevator north of the market): employee number 06288. Access authorized by Walton Simons.", False, True);
	}
}

state Playing
{
Begin:
	if (Talking())
	{
		Sleep(0.5);
		Goto('Begin');
	}
	Sleep(1.0);
	UploadEvidence();
	Sleep(2.0);
Wait:
	if (Talking())
	{
		Sleep(0.5);
		Goto('Wait');
	}
	// goal e flag subito: se JC cambia zona a meta' vale come ascoltato (UCScene.InfoStart)
	NewAssignment();
	SetF('UC_SimonsAfterTong', True);
	InfoStart("WaltonSimons");
	Sleep(1.5);
	n = 0;
Next:
	d = CallLine(n);
	if (d >= 0)
	{
		if (d > 0)
			Sleep(d);
		n++;
		Goto('Next');
	}
	HideInfo();
	Destroy();
}

defaultproperties
{
}
