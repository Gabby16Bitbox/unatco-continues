// 6 October rewrite: native conversations, with knowledge and custody separated.
class UCHKDialogue extends Object;

static function MaxTalks(ScriptedPawn npc)
{
    local UCCon c;

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_MaxAfter', "MaxChen", False);
    c.Require('UC_SwordGivenMax', True);
    c.Line("MaxChen", "JCDenton", "I will call him. The Red Arrow will suspend its attacks.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_MaxWait', "MaxChen", False);
    c.Require('UC_MaxDealOffered', True);
    c.Require('UC_SwordGivenMax', False);
    c.Line("MaxChen", "JCDenton", "Bring me the sword and evidence of what happened to Yuen Kong. Then I will arrange a meeting with Gordon Quick.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_MaxEvidence', "MaxChen", False);
    c.Require('UC_ChowSwordVerified', True);
    c.Require('UC_HasSword', True);
    c.Require('UC_SwordGivenMax', False);
    c.Require('UC_SwordGivenGordon', False);
    c.Choice("Deliver the Dragon's Tooth to Max Chen.", "Deliver", "Keep the weapon as evidence.", "Keep");
    c.Label("Keep");
    c.Line("JCDenton", "MaxChen", "I'll look into Chow. I haven't agreed to hand you a weapon.");
    c.Line("MaxChen", "JCDenton", "Then investigate. We will discuss the weapon when you have it.");
    c.EndHere();
    c.Label("Deliver");
    c.Trigger('UC_GiveSwordMax');
    c.IfFlag('UC_SwordGivenMax', True, "Transferred");
    c.EndHere();
    c.Label("Transferred");
    c.Line("MaxChen", "JCDenton", "You brought it.");
    c.IfFlag('UC_YuenCaseCorroborated', False, "Incomplete");
    c.Line("JCDenton", "MaxChen", "And the records on Yuen Kong.");
    c.Line("MaxChen", "JCDenton", "Miss Chow will answer for him.");
    c.Jump("Agreement");
    c.Label("Incomplete");
    c.Line("JCDenton", "MaxChen", "I can prove she had the sword. Not that she killed him.");
    c.Label("Agreement");
    c.Line("JCDenton", "MaxChen", "Gordon first. That was the agreement.");
    c.Line("MaxChen", "JCDenton", "I will call him. The Red Arrow will suspend its attacks.");
    c.Line("JCDenton", "MaxChen", "And after I leave?");
    c.Line("MaxChen", "JCDenton", "That depends on Gordon Quick.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_MaxMeet', "MaxChen", False);
    c.Require('UC_MaxDealOffered', False);
    c.Radius(190);
    c.IfFlag('UCHongKongRaidStarted',False,"OldArrival");
    c.Line("MaxChen","JCDenton","Mr. Denton. You arrive with government men, and within minutes the Luminous Path is shooting at them.");
    c.Line("JCDenton","MaxChen","They attacked a shipment.");
    c.Line("MaxChen","JCDenton","Yes. A shipment Maggie Chow arranged through Red Arrow channels.");
    c.Line("JCDenton","MaxChen","What was in it?");
    c.Line("MaxChen","JCDenton","If I knew that, I would not need you. Yuen Kong wanted those transfers stopped. Now he is dead, and the Dragon's Tooth is missing.");
    c.Jump("Suspect");
    c.Label("OldArrival");
    c.Line("MaxChen", "JCDenton", "Mr. Denton. You want Tong. I want this war finished.");
    c.Line("JCDenton", "MaxChen", "What's the connection?");
    c.Line("MaxChen", "JCDenton", "Miss Chow. Yuen Kong went to Queen's Tower to question her about the attacks. He never returned.");
    c.Label("Suspect");
    c.Line("JCDenton", "MaxChen", "That makes her a suspect.");
    c.Line("MaxChen", "JCDenton", "The Dragon's Tooth passed through the same building. The Luminous Path claims they never took it.");
    c.Line("JCDenton", "MaxChen", "And you believe them?");
    c.Line("MaxChen", "JCDenton", "I believe someone benefits while we kill each other.");
    c.Line("MaxChen", "JCDenton", "Bring me the sword and evidence of what happened to Yuen Kong. Then I will arrange a meeting with Gordon Quick.");
    c.Line("JCDenton", "MaxChen", "You're asking a UNATCO agent to rob Maggie Chow.");
    c.Line("MaxChen", "JCDenton", "I am asking Paul Denton's brother how badly he wants to find Tong.");
    c.SetFlag('UC_MaxDealOffered', True);
    c.SetFlag('MeetMaxChen_Played', True);
    c.SetFlag('KnowsAboutTriads', True);
    c.Choice("I'll investigate. No promise to deliver the weapon.", "Investigate", "I want information, not a job.", "Decline");
    c.Label("Investigate");
    c.Line("JCDenton", "MaxChen", "I'll look into Chow. I haven't agreed to hand you a weapon.");
    c.Line("MaxChen", "JCDenton", "Then investigate. We will discuss the weapon when you have it.");
    c.EndHere();
    c.Label("Decline");
    c.Line("JCDenton", "MaxChen", "I want information, not a job.");
    c.Line("MaxChen", "JCDenton", "Then ask Miss Chow why Yuen Kong never came home.");
    c.Done();
    c.AttachTo(npc);
}

static function MaggieTalks(ScriptedPawn npc)
{
    local UCCon c;

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_MaggieAgain', "MaggieChow", False);
    c.Require('UC_MaggieRWPlayed', True);
    c.Line("MaggieChow", "JCDenton", "The police have records of the dispute. You may find them more useful than Mr. Chen's suspicions.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_MaggieMeet', "MaggieChow", False);
    c.Require('UC_MaggieRWPlayed', False);
    c.Radius(120);
    c.Line("MaggieChow", "JCDenton", "Mr. Denton. Mr. Simons said you would be coming.");
    c.Line("JCDenton", "MaggieChow", "I'm looking for Tong.");
    c.Line("MaggieChow", "JCDenton", "Then you need Gordon Quick. Unfortunately, his people are keeping the Triads at war.");
    c.Line("JCDenton", "MaggieChow", "Over the Dragon's Tooth.");
    c.Line("MaggieChow", "JCDenton", "A weapon the Luminous Path stole. Recover it, and I can persuade the Red Arrow to negotiate.");
    c.IfFlag('MeetMaxChen_Played', True, "MaxMet");
    c.Line("JCDenton", "MaggieChow", "Why would the Red Arrow listen to you?");
    c.Line("MaggieChow", "JCDenton", "Because I have done business with both sides. They still need someone they can speak to.");
    c.Jump("Yuen");
    c.Label("MaxMet");
    c.Line("JCDenton", "MaggieChow", "Chen thinks the sword came through this building.");
    c.Line("MaggieChow", "JCDenton", "It did. Before it was stolen. Mr. Chen has chosen to forget that distinction.");
    c.Label("Yuen");
    c.Line("JCDenton", "MaggieChow", "What happened to Yuen Kong?");
    c.Line("MaggieChow", "JCDenton", "He died in a conflict Gordon Quick could have ended.");
    c.IfFlag('MeetMaxChen_Played', False, "MaxAbsent");
    c.Line("JCDenton", "MaggieChow", "Max says he came here.");
    c.Jump("Grave");
    c.Label("MaxAbsent");
    c.Line("JCDenton", "MaggieChow", "Did he come here?");
    c.Label("Grave");
    c.Line("MaggieChow", "JCDenton", "He came here often. That does not make this his grave.");
    c.Line("JCDenton", "MaggieChow", "Where should I start?");
    c.Line("MaggieChow", "JCDenton", "The police have records of the dispute. You may find them more useful than Mr. Chen's suspicions.");
    c.SetFlag('UC_MaggieRWPlayed', True);
    c.SetFlag('UC_MaggieMeet_Played', True);
    c.SetFlag('MeetMaggie_Played', True);
    c.SetFlag('KnowsAboutMaggie', True);
    c.SetFlag('KnowsAboutTriads', True);
    c.SetFlag('FoundMaggieChow', True);
    c.Trigger('MaggieWanders');
    c.Done();
    c.AttachTo(npc);
}

static function GordonPermit(UCCon c)
{
    c.Line("GordonQuick", "JCDenton", "You expose Chow and expect us to forget why you're here.");
    c.Line("JCDenton", "GordonQuick", "I'm here for Tong.");
    c.Line("GordonQuick", "JCDenton", "Exactly.");
    c.Line("GordonQuick", "JCDenton", "Paul came here as a friend. You came here with orders.");
    c.Line("JCDenton", "GordonQuick", "Then let Tong hear them himself.");
    c.Line("GordonQuick", "JCDenton", "He has agreed to a meeting. Nothing more. Nineteen ninety-seven. The door in our sparring room.");
    c.SetFlag('UC_LPMeetingGranted', True);
    c.SetFlag('QuickLetPlayerIn', True);
    c.SetFlag('Gate_Guard2_Played', True);
}

static function GordonTalks(ScriptedPawn npc)
{
    local UCCon c;

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_GordonWait', "GordonQuick", False);
    c.Require('UC_GordonMeet_Played', True);
    c.Require('UC_ChowSwordVerified', False);
    c.Line("GordonQuick", "JCDenton", "Then ask her why Yuen Kong went to Queen's Tower. Bring an answer, not another accusation.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_GordonAgain', "GordonQuick", False);
    c.Require('UC_LPMeetingGranted', True);
    c.Line("GordonQuick", "JCDenton", "He has agreed to a meeting. Nothing more. Nineteen ninety-seven. The door in our sparring room.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_GordonCustody', "GordonQuick", False);
    c.Require('UC_LPMeetingGranted', True);
    c.Require('UC_HasSword', True);
    c.Require('UC_SwordGivenGordon', False);
    c.Require('UC_SwordGivenMax', False);
    c.Choice("Transfer the Dragon's Tooth to Gordon.", "Give", "Keep the weapon as evidence.", "Keep");
    c.Label("Give");
    c.Trigger('UC_GiveSwordGordon');
    c.EndHere();
    c.Label("Keep");
    c.Line("JCDenton", "GordonQuick", "I'm retaining the weapon as evidence.");
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_GordonFinal', "GordonQuick", False);
    c.Require('UC_SwordGivenMax', True);
    c.Require('UC_LPMeetingGranted', False);
    GordonPermit(c);
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_GordonEvidence', "GordonQuick", False);
    c.Require('UC_ChowSwordVerified', True);
    c.Require('UC_SwordGivenMax', False);
    c.Require('UC_LPMeetingGranted', False);
    c.Choice("Share the records with the Red Arrow.", "Copy", "Retain the weapon; submit the records.", "Retain");
    c.Label("Copy");
    c.IfFlag('UC_YuenCaseCorroborated', False, "OnlySword");
    c.Line("JCDenton", "GordonQuick", "The sword was in Chow's apartment. These are her records on Yuen Kong.");
    c.Line("GordonQuick", "JCDenton", "And Chen has seen them?");
    c.Line("JCDenton", "GordonQuick", "He can have a copy. He doesn't need the weapon to read it.");
    c.Line("GordonQuick", "JCDenton", "Then he can decide whether he wants an answer or an excuse to keep fighting.");
    c.Jump("Permit");
    c.Label("OnlySword");
    c.Line("JCDenton", "GordonQuick", "I can prove she had the sword. Not that she killed him.");
    c.Jump("Permit");
    c.Label("Retain");
    c.IfFlag('UC_HasSword', False, "SwordAbsent");
    c.Line("JCDenton", "GordonQuick", "I'm retaining the weapon as evidence.");
    c.Line("GordonQuick", "JCDenton", "UNATCO gets the sword. What do we get?");
    c.Jump("Records");
    c.Label("SwordAbsent");
    c.IfFlag('UC_SwordAtChow', False, "OnlySword");
    c.IfFlag('UC_YuenCaseCorroborated', False, "OnlySword");
    c.Line("JCDenton", "GordonQuick", "The sword is still at Queen's Tower. I brought the records.");
    c.Label("Records");
    c.IfFlag('UC_YuenCaseCorroborated', False, "OnlySword");
    c.Line("JCDenton", "GordonQuick", "Chow's records. And a chance to tell Tong what I'm actually here to do.");
    c.Line("GordonQuick", "JCDenton", "He already knows. He wants to hear it from you.");
    c.Label("Permit");
    c.SetFlag('UC_ChowEvidenceSentGordon', True);
    GordonPermit(c);
    c.Done();
    c.AttachTo(npc);

    c = new(npc.Level) class'UCCon';
    c.Begin('UC_GordonMeet', "GordonQuick", False);
    c.Once();
    c.Radius(180);
    c.Require('UC_ChowSwordVerified', False);
    c.Require('UC_LPMeetingGranted', False);
    c.Line("GordonQuick", "JCDenton", "Paul came here as a friend. You came here with orders.");
    c.Line("JCDenton", "GordonQuick", "I'm looking for Tong.");
    c.Line("GordonQuick", "JCDenton", "We know.");
    c.IfFlag('UC_MaggieRWPlayed', False, "MaggieAbsent");
    c.Line("JCDenton", "GordonQuick", "Chow says your people stole the Dragon's Tooth.");
    c.Jump("Answer");
    c.Label("MaggieAbsent");
    c.Line("JCDenton", "GordonQuick", "I need to know what happened to the Dragon's Tooth.");
    c.Label("Answer");
    c.Line("GordonQuick", "JCDenton", "Then ask her why Yuen Kong went to Queen's Tower. Bring an answer, not another accusation.");
    c.SetFlag('Gate_Guard2_Played', True);
    c.SetFlag('KnowsAboutMaggie', True);
    c.SetFlag('KnowsAboutNanoSword', True);
    c.Done();
    c.AttachTo(npc);
}
