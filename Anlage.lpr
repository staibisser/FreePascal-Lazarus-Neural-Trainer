PROGRAM Anlage;


(*
  Free Pascal Neural Trainer
  Copyright (C) 2024 Christof Biner

  Dieses Programm ist freie Software. Sie können es unter den Bedingungen
  der GNU General Public License, wie von der Free Software Foundation veröffentlicht,
  weitergeben und/oder modifizieren – entweder gemäß Version 3 der Lizenz oder (nach Ihrer Wahl)
  jeder späteren Version.

  Dieses Programm wird in der Hoffnung verbreitet, dass es nützlich ist,
  aber OHNE JEDE GEWÄHRLEISTUNG – sogar ohne die implizite Gewährleistung
  der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
  Siehe die GNU General Public License für weitere Details.

  Sie sollten eine Kopie der GNU General Public License zusammen mit diesem Programm erhalten haben.
  Falls nicht, siehe <https://www.gnu.org/licenses/>.
*)

{$mode objfpc}{$H+}

USES
  {$IFDEF UNIX}
                  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
                  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  tachartlazaruspkg,
  main { you can add units after this };

  {$R *.res}

BEGIN
  RequireDerivedFormResource := TRUE;
		  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
  {$IFDEF DEBUG}
  PrintLeaksToFile('memoryleaks.log');
  {$ENDIF}
END.
