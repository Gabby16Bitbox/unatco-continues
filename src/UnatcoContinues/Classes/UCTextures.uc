//=============================================================================
// UCTextures - texture della mod (importate nel pacchetto UnatcoContinues).
//  UCSignElevators: la scritta "ELEVATORS" sopra la porta blindata dell'eliporto di
//  Hong Kong, rifatta sulla scritta HD di Revision (NewVision HK_Helibase.Sn_HBLkdwn,
//  1024x128 compressa): stesso fondo rosso e cornice, lettere in corsivo come LOCKDOWN.
//  1024x128 a 256 colori (sorgente a colori: Textures\UCSignElevators_sorgente.png).
//  La mette UCMod.SwapHelibaseSign solo nella variante UNATCO, con DrawScale 0.125.
//=============================================================================
class UCTextures extends Object
	abstract;

#exec TEXTURE IMPORT NAME=UCSignElevators FILE=Textures\UCSignElevators.pcx MIPS=On

defaultproperties
{
}
