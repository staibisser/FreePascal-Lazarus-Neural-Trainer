UNIT main;

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

INTERFACE

USES
  {$IFDEF DEBUG}
   heaptrc,
  {$ENDIF} Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, neuralnetwork, neuralvolume, neuralfit,
  DateUtils, Math, IniFiles,
  {Reihenfolge der TCart Komponenten beachten}
  TAGraph, TASeries, TAChartAxisUtils, TATransformations, TAChartUtils,
  TAChartAxis, TATypes, TATools, TATextElements,
  TALegend, TAIntervalSources, TACustomSeries;

TYPE

  { TForm1 }

  TForm1 = CLASS(TForm)
    Chart1:      TChart;
    ChartToolset1: TChartToolset;
    DateTimeIntervalChartSource: TDateTimeIntervalChartSource;
    InputValueLabels1: TLabel;
    InputValueLabels2: TLabel;
    InputValueLabels3: TLabel;
    InputTrackBar1: TTrackBar;
    InputTitelLabel: TLabel;
    InputValueLabels5: TLabel;
    InputValueLabels6: TLabel;
    InputValueLabels7: TLabel;
    OutputValueLabels10: TLabel;
    OutputValueLabels11: TLabel;
    OutputValueLabels12: TLabel;
    OutputValueLabels13: TLabel;
    OutputValueLabels14: TLabel;
    OutputValueLabels15: TLabel;
    OutputValueLabels16: TLabel;
    OutputValueLabels2: TLabel;
    OutputValueLabels3: TLabel;
    OutputValueLabels4: TLabel;
    OutputValueLabels5: TLabel;
    OutputValueLabels6: TLabel;
    OutputValueLabels17: TLabel;
    OutputValueLabels7: TLabel;
    OutputValueLabels8: TLabel;
    OutputLabel4: TLabel;
    OutputLabel5: TLabel;
    OutputLabel6: TLabel;
    OutputLabel7: TLabel;
    OutputLabel8: TLabel;
    OutputValueLabels1: TLabel;
    OutputTitelLabel: TLabel;
    InputLabel1: TLabel;
    InputLabel2: TLabel;
    InputLabel3: TLabel;
    OutputLabel1: TLabel;
    OutputLabel2: TLabel;
    OutputLabel3: TLabel;
    OutputTrackBar6: TTrackBar;
    OutputTrackBar7: TTrackBar;
    OutputTrackBar8: TTrackBar;
    InputTrackBar2: TTrackBar;
    InputTrackBar3: TTrackBar;
    OutputTrackBar1: TTrackBar;
    OutputTrackBar2: TTrackBar;
    OutputTrackBar3: TTrackBar;
    OutputTrackBar4: TTrackBar;
    OutputTrackBar5: TTrackBar;
    LogMemo:     TMemo;
    OpenDialog:  TOpenDialog;
    ModelLadenButton: TButton;
    SaveDialog:  TSaveDialog;
    StatusBar:   TStatusBar;
    TimerChartUpdate: TTimer;
    TrainButton: TButton;
    OptimizeButton: TButton;
    LoadCSVButton: TButton;
    NormalizeButton: TButton;
    PredictionButton: TButton;
    PROCEDURE FormCloseQuery(Sender: TObject; VAR CanClose: BOOLEAN);
    PROCEDURE FormCreate(Sender: TObject);
    PROCEDURE FormDestroy(Sender: TObject);
    PROCEDURE InputTrackBarClick(Sender: TObject);
    PROCEDURE LoadCSVButtonClick(Sender: TObject);
    PROCEDURE ModelLadenButtonClick(Sender: TObject);
    PROCEDURE NormalizeButtonClick(Sender: TObject);
    PROCEDURE OptimizeButtonClick(Sender: TObject);
    PROCEDURE OutputTrackBarClick(Sender: TObject);
    PROCEDURE PredictionButtonClick(Sender: TObject);
    PROCEDURE TimerChartUpdateTimer(Sender: TObject);
    PROCEDURE TrainButtonClick(Sender: TObject);
    PROCEDURE SchieberChanged(Sender: TObject);
    PROCEDURE OutputSchieberChanged(Sender: TObject);
    PROCEDURE LogMessage(CONST Msg: STRING);

    PROCEDURE SetupChart;


    PROCEDURE LoadModelWithMetadata(ModelFilename, MetadataFilename: STRING);
    PROCEDURE SaveModelWithMetadata(ModelFilename, MetadataFilename: STRING);

  private
    //InputVolume, OutputVolume: TNNetVolume;
    NN: TNNet;

    // Volumes für Ein- und Ausgabe
    FInputVolume, FOutputVolume: TNNetVolume;

    // Für Zeitmessung
    BeginTime: TDateTime;
    FPreviousComputeTime: TDateTime;
  public

  END;

VAR
  Form1: TForm1;

IMPLEMENTATION

CONST

  // Konstanten für die CSV-Verarbeitung
  CSV_SEPARATOR     = ';';
  DECIMAL_SEPARATOR = ',';

VAR
  InputCount:  INTEGER = 3;
  OutputCount: INTEGER = 5;
  MinInputs, MaxInputs: ARRAY OF DOUBLE;
  MinOutputs, MaxOutputs: ARRAY OF DOUBLE;
  InputData, OutputData: ARRAY OF ARRAY OF DOUBLE;


  NormalizedInputData, NormalizedOutputData: ARRAY OF ARRAY OF DOUBLE;

  // Input parameters
  InputTrackBars:   ARRAY OF TTrackBar;
  InputLabels:      ARRAY OF TLabel;
  InputValueLabels: ARRAY OF TLabel;
  InputSeries:      ARRAY OF TLineSeries;

  // Output parameters
  OutputTrackBars:   ARRAY OF TTrackBar;
  OutputLabels:      ARRAY OF TLabel;
  OutputValueLabels: ARRAY OF TLabel;
  OutputSeries:      ARRAY OF TLineSeries;

  { Hilfsvariable für Optimierungsmodus }


  ClickInputIdx:  INTEGER = -1;
  ClickOutputIdx: INTEGER = -1;      // Index des bewegten Ausgangreglers

  {$R *.lfm}

  { TForm1 }

  // ---------------- Hilfs Proceduren  ----------------

FUNCTION Normalize(Value, MinValue, MaxValue: DOUBLE): DOUBLE;
    // Normalisieren eines Wertes auf [0,1]
  BEGIN
    IF MaxValue>MinValue THEN
      Result := (Value-MinValue)/(MaxValue-MinValue)
    ELSE
      Result := 0.5;

    // Sicherstellen, dass der Wert im Bereich [0,1] liegt
    IF Result<0 THEN Result := 0;
    IF Result>1 THEN Result := 1;
  END;


FUNCTION Denormalize(NormalizedValue, MinValue, MaxValue: DOUBLE): DOUBLE;
    // Denormalisieren eines Wertes von [0,1]
  BEGIN
    Result := NormalizedValue*(MaxValue-MinValue)+MinValue;
  END;


FUNCTION StrToFloatDE(CONST S: STRING): DOUBLE;
    // Wandelt einen String mit Komma als Dezimaltrennzeichen in Double um
  VAR
    TempStr: STRING;
  BEGIN
    TempStr := StringReplace(S, DECIMAL_SEPARATOR, '.', [rfReplaceAll]);
    Result  := StrToFloatDef(TempStr, 0.0);
  END;


PROCEDURE TForm1.LogMessage(CONST Msg: STRING);
  // Protokollierung von Nachrichten ins Memo-Log-Feld
  BEGIN
    LogMemo.Lines.Add(Msg);
    LogMemo.SelStart := Length(LogMemo.Text);  // Automatisches Scrollen
  END;

// ---------------- GUI Proceduren  ----------------

PROCEDURE TForm1.PredictionButtonClick(Sender: TObject);
  VAR
    i: INTEGER;
    NormalizedValue, DenormalizedValue: DOUBLE;
  BEGIN
    LogMemo.Clear;
    TimerChartUpdate.Enabled := TRUE;
    // Eingabe-Schieberegler aktivieren
    FOR i := 0 TO InputCount-1 DO
      IF InputTrackBars[i]<>NIL THEN
        BEGIN
        // Schieberegler aktivieren
        InputTrackBars[i].Enabled := TRUE;

        // Schieberegler auf Mittelposition setzen (angenommen, der Bereich ist 0-100)

        // Normalisierte und denormalisierte Werte berechnen
        NormalizedValue   := InputTrackBars[i].Position; // Mittelposition
        DenormalizedValue := Denormalize(NormalizedValue, MinInputs[i], MaxInputs[i]);

        // Wert-Label mit denormalisiertem Wert aktualisieren
        IF InputValueLabels[i]<>NIL THEN
          InputValueLabels[i].Caption := FloatToStrF(DenormalizedValue, ffFixed, 6, 2);

        // Wert-Label aktualisieren
        IF InputValueLabels[i]<>NIL THEN
          InputValueLabels[i].Caption := IntToStr(InputTrackBars[i].Position);
        END;

    // Initial eine Vorhersage durchführen
    SchieberChanged(NIL);

    // Ausgansschieber deaktivieren
    FOR i := 0 TO OutputCount-1 DO
      IF (i<Length(OutputTrackBars)) AND (OutputTrackBars[i]<>NIL) THEN
        BEGIN
        OutputTrackBars[i].Enabled  := FALSE;
        OutputTrackBars[i].OnChange := NIL;
        END;
    // Timer für Grafik freischalten
    TimerChartUpdate.Enabled := TRUE;
    OptimizeButton.Enabled   := TRUE;
    PredictionButton.Enabled := FALSE;

    // Status-Nachricht
    LogMessage('🔄 Vorhersagemodus aktiviert. Bewegen Sie die Schieberegler, um die Vorhersage zu ändern.');
    StatusBar.SimpleText :=
      '🔄 Vorhersagemodus aktiviert. Bewegen Sie die Schieberegler, um die Vorhersage zu ändern.';
  END;

PROCEDURE TForm1.TimerChartUpdateTimer(Sender: TObject);
  VAR
    i: INTEGER;
    InputValue, OutputValue: DOUBLE;
  BEGIN
    // Aktuelle Werte aus den Labels lesen und im Chart darstellen
    // Input-Werte
      TRY
      FOR i := 0 TO InputCount-1 DO
        BEGIN
        // Text aus Label in Float umwandeln
        InputValue := StrToFloat(InputValueLabels[i].Caption);
        // Wert zur Serie hinzufügen
        IF ClickInputIdx = i THEN
          InputSeries[i].AddXY(Now, InputValue, InputValue.ToString)
        ELSE;
        InputSeries[i].AddXY(Now, InputValue);
        END;
      ClickInputIdx := -1;
      // Output-Werte
      FOR i := 0 TO OutputCount-1 DO
        BEGIN
        // Text aus Label in Float umwandeln
        OutputValue := StrToFloat(OutputValueLabels[i].Caption);
        // Wert zur Serie hinzufügen
        IF ClickOutputIdx = i THEN
          OutputSeries[i].AddXY(Now, OutputValue, OutputValue.ToString)
        ELSE
          OutputSeries[i].AddXY(Now, OutputValue);
        END;
      ClickOutputIdx := -1;
      EXCEPT
      on E: Exception DO
        BEGIN
        LogMessage('❌ Fehler Grafik: '+E.Message);
        Exit;
        END;
      END;
  END;

PROCEDURE TForm1.LoadCSVButtonClick(Sender: TObject);
  VAR
    CSV: TStringList;
    Lines, Values: TStringList;
    Row, Col, i: INTEGER;
  BEGIN

      TRY
      CSV    := TStringList.Create;
      Lines  := TStringList.Create;
      Values := TStringList.Create;

        TRY
        OpenDialog.CleanupInstance;
        OpenDialog.Title      := '📂 csv Datei laden';
        OpenDialog.DefaultExt := 'csv';  // Ohne Punkt!
        OpenDialog.Filter     := 'csv Dateien (*.csv)|*.csv|Alle Dateien (*.*)|*.*';
        OpenDialog.FilterIndex := 1;

        // Dateidialog öffnen
        IF NOT OpenDialog.Execute THEN
          LogMessage('⚠️ Kein Dateiname ausgewählt. Abbruch.');
        // Datei laden
        CSV.LoadFromFile(OpenDialog.FileName);
        LogMessage('📂 Lade CSV-Datei: '+OpenDialog.FileName);
        Lines.Text := CSV.Text;
        LogMessage('📊 Zeilenanzahl: '+IntToStr(Lines.Count));
        IF Lines.Count<=1 THEN
          BEGIN
          LogMessage('❌ CSV-Datei enthält keine oder zu wenige Daten.');
          Exit;
          END;
        EXCEPT
        on E: Exception DO
          BEGIN
          LogMessage('❌ Fehler Datei lesen : '+E.Message);
          Exit;
          END;
        END;

      // Arrays initialisieren
      SetLength(MinInputs, InputCount);
      SetLength(MaxInputs, InputCount);
      SetLength(MinOutputs, OutputCount);
      SetLength(MaxOutputs, OutputCount);
      SetLength(InputData, Lines.Count-1, InputCount);
      SetLength(OutputData, Lines.Count-1, OutputCount);

      // Hilfsobjekt für die Werte konfigurieren
      Values.Delimiter := CSV_SEPARATOR;
      Values.StrictDelimiter := TRUE;

      // Alle Daten einlesen (ab Zeile 2, da Zeile 1 Header ist)
      FOR Row := 1 TO Lines.Count-1 DO
        BEGIN
        Values.DelimitedText := Lines[Row];

        // Sicherstellen, dass genügend Spalten vorhanden sind
        IF Values.Count<InputCount+OutputCount THEN
          BEGIN
          WriteLn('Warnung: Zeile ', Row,
            ' hat nicht genügend Spalten. Überspringe Zeile.');
          Continue;
          END;

        // Eingabedaten einlesen
        FOR Col := 0 TO InputCount-1 DO
          BEGIN
          InputData[Row-1][Col] := StrToFloatDE(Values[Col]);

          // Min/Max initialisieren bei der ersten Zeile
          IF Row = 1 THEN
            BEGIN
            MinInputs[Col] := InputData[Row-1][Col];
            MaxInputs[Col] := InputData[Row-1][Col];
            END
          ELSE
            BEGIN
            // Min/Max aktualisieren
            IF InputData[Row-1][Col]<MinInputs[Col] THEN
              MinInputs[Col] := InputData[Row-1][Col];
            IF InputData[Row-1][Col]>MaxInputs[Col] THEN
              MaxInputs[Col] := InputData[Row-1][Col];
            END;
          END;

        // Ausgabedaten einlesen
        FOR Col := 0 TO OutputCount-1 DO
          BEGIN
          OutputData[Row-1][Col] := StrToFloatDE(Values[Col+InputCount]);

          // Min/Max initialisieren bei der ersten Zeile
          IF Row = 1 THEN
            BEGIN
            MinOutputs[Col] := OutputData[Row-1][Col];
            MaxOutputs[Col] := OutputData[Row-1][Col];
            END
          ELSE
            BEGIN
            // Min/Max aktualisieren
            IF OutputData[Row-1][Col]<MinOutputs[Col] THEN
              MinOutputs[Col] := OutputData[Row-1][Col];
            IF OutputData[Row-1][Col]>MaxOutputs[Col] THEN
              MaxOutputs[Col] := OutputData[Row-1][Col];
            END;
          END;
        END;
      // Min/Max erweitern


      // Informationen über die geladenen Daten ausgeben
      LogMessage('✅ Daten geladen: '+IntToStr(Lines.Count-1)+' Datensätze');
      NormalizeButton.Enabled := TRUE;
      StatusBar.SimpleText    :=
        '✅ CSV Daten importiert: '+IntToStr(Lines.Count-1)+' Datensätze';

      FINALLY
      CSV.Free;
      Lines.Free;
      Values.Free;
      END;

  END;

PROCEDURE TForm1.ModelLadenButtonClick(Sender: TObject);
  BEGIN
    IF NOT Assigned(NN) THEN
      ShowMessage('🚫 Kein Netzwerk kreiert...');

    // OpenDialog konfigurieren
    OpenDialog.Title      := '💾 Neuronales Netzwerk speichern';
    OpenDialog.DefaultExt := 'nn';  // Ohne Punkt!
    OpenDialog.Filter     := 'Neural Network Dateien (*.nn)|*.nn|Alle Dateien (*.*)|*.*';
    OpenDialog.FilterIndex := 1;

    // Dialog anzeigen
    IF OpenDialog.Execute THEN
      LoadModelWithMetadata(OpenDialog.Filename,
        ChangeFileExt(OpenDialog.Filename, '.meta'));

    LogMessage('✅ Bestehendes Modell und Metadaten geladen.');
    OptimizeButton.Enabled   := TRUE;
    PredictionButton.Enabled := TRUE;
    StatusBar.SimpleText     := '✅ Bestehendes Modell und Metadaten geladen.';
  END;

PROCEDURE TForm1.SetupChart;
  VAR
    i: INTEGER;
    inputAxis, outputAxis: TChartAxis;
    inputTransform, outputTransform: TAutoScaleAxisTransform;
    AufteilungAxis: DOUBLE;
  BEGIN
    Chart1.ClearSeries;
    Chart1.Legend.Visible := TRUE;

    AufteilungAxis := 1/(InputCount+OutputCount);

      TRY
      // Eingabeserien und -achsen erstellen (links)
      FOR i := 0 TO InputCount-1 DO
        BEGIN

        // Neue Achse anlegen
        inputAxis := Chart1.AxisList.Add;
        inputAxis.Alignment := calLeft;
        ;
        //inputAxis.Title.Caption := Format('Eingang %d', [i+1]);
        inputAxis.Title.Caption := InputLabels[i].Caption;
        inputAxis.Title.Visible := TRUE;
        inputAxis.Title.LabelFont.Orientation := 900;

        // Achsenfarbe aus Farbschema festlegen
        inputAxis.Title.LabelFont.Color := clRed;
        inputAxis.Marks.LabelFont.Color := clRed;
        inputAxis.AxisPen.Color := clRed;

        // Achseneigenschaften für bessere Lesbarkeit
        inputAxis.Marks.AtDataOnly := TRUE;
        inputAxis.AtDataOnly := TRUE;
        inputAxis.Title.PositionOnMarks := TRUE;
        inputAxis.Group      := 10;

        // Transformation für die Achse
        inputAxis.Transformations := TChartAxisTransformations.Create(Chart1);
        inputTransform := TAutoScaleAxisTransform.Create(inputAxis.Transformations);
        inputTransform.Transformations := inputAxis.Transformations;


        // Wertebereich auf dem Chart aufteilen (wie im ursprünglichen Beispiel)
        inputTransform.MinValue := (i*AufteilungAxis);
        inputTransform.MaxValue := (i*AufteilungAxis)+(0.8*AufteilungAxis);


        // Serie erstellen
        InputSeries[i] := TLineSeries.Create(Chart1);
        InputSeries[i].SeriesColor := clRed;
        InputSeries[i].Title := Format('Eingang %d', [i+1]);

        // Linienstil
        InputSeries[i].LinePen.Style := psSolid;
        InputSeries[i].LinePen.Width := 2;

        // Markerstil
        InputSeries[i].Pointer.Style   := psCircle;
        InputSeries[i].Pointer.Brush.Color := clRed;
        InputSeries[i].Pointer.Visible := FALSE;

        // Label vorbereiten
        InputSeries[i].Marks.Style := smsLabel;    // Nur das Label anzeigen
        InputSeries[i].Marks.LabelFont.Orientation := 900;
        InputSeries[i].Marks.Arrow.Length := 3;
        InputSeries[i].Marks.Arrow.BaseLength := 0;
        InputSeries[i].Marks.Arrow.Width := 1;
        InputSeries[i].Marks.Arrow.Visible := TRUE; //  Pfeile zur Markierung
        InputSeries[i].Marks.LinkDistance := 0;
        InputSeries[i].Marks.LinkPen.Style := psSolid;
        InputSeries[i].Marks.LinkPen.Width := 1;
        InputSeries[i].Marks.LinkPen.Color := clRed;
        InputSeries[i].Marks.LinkPen.Visible := TRUE;
        InputSeries[i].StackedNaN  := snDoNotDraw;


        // Y-Achse (neu erstellte)
        InputSeries[i].AxisIndexY := inputAxis.Index;

        //X-Achse (Standard-X-Achse ist normalerweise Index 1 bei TChart)
        InputSeries[i].AxisIndexX := 1;

        // Label vorbereiten
        InputSeries[i].Marks.Style   := smsLabel;    // Nur das Label anzeigen
        InputSeries[i].Marks.LabelFont.Orientation := 900;
        InputSeries[i].Marks.Arrow.Length := 10;
        InputSeries[i].Marks.Arrow.BaseLength := 0;
        InputSeries[i].Marks.Arrow.Width := 5;
        InputSeries[i].Marks.Arrow.Visible := TRUE; //  Pfeile zur Markierung
        InputSeries[i].Marks.LinkDistance := 0;
        InputSeries[i].Marks.LinkPen.Style := psSolid;
        InputSeries[i].Marks.LinkPen.Width := 2;
        InputSeries[i].Marks.LinkPen.Color := clRed;
        InputSeries[i].Marks.LinkPen.Visible := TRUE;
        InputSeries[i].StackedNaN    := snDoNotDraw;
        InputSeries[i].Marks.Visible := TRUE;

        Chart1.AddSeries(InputSeries[i]);

        END;
      EXCEPT
      on E: Exception DO
        BEGIN
        LogMessage('❌ InputSeries: '+E.Message);
        END;
      END;

      TRY

      // Ausgabeserien und -achsen erstellen (rechts)
      FOR i := 0 TO OutputCount-1 DO
        BEGIN
        // Neue Achse anlegen
        outputAxis := Chart1.AxisList.Add;
        outputAxis.Alignment := calLeft;
        outputAxis.Title.Caption := OutputLabels[i].Caption;
        outputAxis.Title.Visible := TRUE;
        outputAxis.Title.LabelFont.Orientation := 900;  // Senkrecht (in 1/10 Grad)

        // VERBESSERUNG 1: Farbschema anwenden
        outputAxis.Title.LabelFont.Color := clBlue;
        outputAxis.Marks.LabelFont.Color := clBlue;
        outputAxis.AxisPen.Color := clBlue;

        // Achseneigenschaften für bessere Lesbarkeit
        outputAxis.Marks.AtDataOnly := TRUE;
        outputAxis.AtDataOnly := TRUE;
        outputAxis.Title.PositionOnMarks := TRUE;
        outputAxis.Group      := 10;

        // Transformation
        outputAxis.Transformations := TChartAxisTransformations.Create(Chart1);
        outputTransform := TAutoScaleAxisTransform.Create(outputAxis.Transformations);
        outputTransform.Transformations := outputAxis.Transformations;

        // Wertebereich auf dem Chart
        outputTransform.MinValue := (i+InputCount)*(AufteilungAxis);
        outputTransform.MaxValue := (i+InputCount)*(AufteilungAxis)+0.8*AufteilungAxis;

        // Serie erstellen
        OutputSeries[i] := TLineSeries.Create(Chart1);
        OutputSeries[i].SeriesColor := clBlue;
        OutputSeries[i].Title := Format('Ausgang %d', [i+1]);

        // Linienstil
        OutputSeries[i].LinePen.Style := psSolid;
        OutputSeries[i].LinePen.Width := 2;

        // Markerstil (Rechtecke für Ausgabe im Gegensatz zu Kreisen für Eingabe)
        OutputSeries[i].Pointer.Style   := psRectangle;
        OutputSeries[i].Pointer.Brush.Color := clBlue;
        OutputSeries[i].Pointer.Visible := FALSE;


        // Labels definieren
        OutputSeries[i].Marks.Visible := TRUE;
        OutputSeries[i].Marks.Style   := smsLabel;    // Nur das Label anzeigen
        OutputSeries[i].Marks.LabelFont.Orientation := 900;
        OutputSeries[i].Marks.Arrow.Length := 10;
        OutputSeries[i].Marks.Arrow.BaseLength := 0;
        OutputSeries[i].Marks.Arrow.Width := 5;
        OutputSeries[i].Marks.Arrow.Visible := TRUE; //  Pfeile zur Markierung
        OutputSeries[i].Marks.LinkDistance := 0;
        OutputSeries[i].Marks.LinkPen.Style := psSolid;
        OutputSeries[i].Marks.LinkPen.Width := 2;
        OutputSeries[i].Marks.LinkPen.Color := clBlue;
        OutputSeries[i].Marks.LinkPen.Visible := TRUE;
        OutputSeries[i].StackedNaN    := snDoNotDraw;

        // Y-Achse (neu erstellte)
        OutputSeries[i].AxisIndexY := outputAxis.Index;

        // X-Achse
        OutputSeries[i].AxisIndexX := 1;

        Chart1.AddSeries(OutputSeries[i]);
        END;

      EXCEPT
      on E: Exception DO
        BEGIN
        LogMessage('❌ OutputSeries: '+E.Message);
        END;
      END;
    // Allgemeine Chart-Einstellungen
    Chart1.Title.Text.Clear;
    Chart1.Title.Text.Add('Eingabe- und Ausgabewerte Achsen');
    Chart1.Title.Visible    := TRUE;
    Chart1.Title.Font.Size  := 12;
    Chart1.Title.Font.Style := [fsBold];

    Chart1.Legend.Visible   := FALSE;
    Chart1.Legend.Alignment := laTopCenter;


    // Optional: Toolset für interaktives Zoomen/Verschieben
    IF NOT Assigned(ChartToolset1) THEN
      BEGIN
      ChartToolset1  := TChartToolset.Create(Chart1);
      Chart1.Toolset := ChartToolset1;

      WITH TZoomDragTool.Create(ChartToolset1) DO
        BEGIN
        Shift := [ssLeft];
        Brush.Style := bsClear;
        END;

      WITH TPanDragTool.Create(ChartToolset1) DO
        Shift := [ssRight];
      END;

    // Initial-Zoom
    Chart1.ZoomFull;
  END;

PROCEDURE TForm1.FormCreate(Sender: TObject);
  VAR
    i: INTEGER;
  BEGIN
    // Anzahl der Eingänge und Ausgänge bestimmen
    LogMemo.Clear;
    logMessage('Arbeitsverzeichnis: '+GetCurrentDir);
    logMessage('Programmpfad:       '+ExtractFilePath(ParamStr(0)));

    // 1. Arrays auf die richtige Größe anpassen
    SetLength(InputTrackBars, InputCount);
    SetLength(InputLabels, InputCount);
    SetLength(InputValueLabels, InputCount);
    SetLength(InputSeries, InputCount);

    SetLength(OutputTrackBars, OutputCount);
    SetLength(OutputLabels, OutputCount);
    SetLength(OutputValueLabels, OutputCount);
    SetLength(OutputSeries, OutputCount);

    // 2. Bestehende Komponenten den Arrays zuweisen

    // Eingabe-Komponenten zuweisen
    FOR i := 0 TO InputCount-1 DO
      BEGIN
      // Komponenten anhand eines Namensmusters finden und zuweisen
      InputTrackBars[i]   := TTrackBar(FindComponent('InputTrackBar'+IntToStr(i+1)));
      InputLabels[i]      := TLabel(FindComponent('InputLabel'+IntToStr(i+1)));
      InputValueLabels[i] := TLabel(FindComponent('InputValueLabels'+IntToStr(i+1)));

      IF InputTrackBars[i]<>NIL THEN
        InputTrackBars[i].Enabled := FALSE;

      // Sicherheitsüberprüfung
      IF InputTrackBars[i] = NIL THEN
        RAISE Exception.Create('Komponente InputTrackBar'+IntToStr(i+1)+
          ' nicht gefunden!');
      InputTrackBars[i].Position := 50;
      // Optional: Event-Handler zuweisen, on change aktiv!
      InputTrackBars[i].OnChange := @SchieberChanged;
      InputTrackBars[i].OnClick  := @InputTrackBarClick;
      END;

    // Ausgabe-Komponenten zuweisen
    FOR i := 0 TO OutputCount-1 DO
      BEGIN
      OutputTrackBars[i]   := TTrackBar(FindComponent('OutputTrackBar'+IntToStr(i+1)));
      OutputLabels[i]      := TLabel(FindComponent('OutputLabel'+IntToStr(i+1)));
      OutputValueLabels[i] := TLabel(FindComponent('OutputValueLabels'+IntToStr(i+1)));

      // Optional: Ausgabe-Schieberegler deaktivieren, da sie nur zur Anzeige dienen
      IF OutputTrackBars[i]<>NIL THEN
        BEGIN
        OutputTrackBars[i].Enabled  := FALSE;
        OutputTrackBars[i].Position := 50;
        //OutputTrackBars[i].OnChange := @OutputSchieberChanged;
        outputTrackbars[i].OnClick  := @OutputTrackBarClick;
        END;
      END;

    NormalizeButton.Enabled  := FALSE;
    TrainButton.Enabled      := FALSE;
    PredictionButton.Enabled := FALSE;
    OptimizeButton.Enabled   := FALSE;

    // Netzwerk erzeugen


    // Netzwerk erstellen
    IF NOT Assigned(NN) THEN
      BEGIN
      NN := TNNet.Create();
      NN.AddLayer(TNNetInput.Create(1, 1, InputCount));
      NN.AddLayer(TNNetFullConnectReLU.Create(64));
      NN.AddLayer(TNNetFullConnectReLU.Create(32));
      NN.AddLayer(TNNetFullConnect.Create(OutputCount));
      NN.SetLearningRate(0.001, 0.9); // Lernrate und Momentum
      END;

    // Volumes einmalig erstellen
    FInputVolume  := TNNetVolume.Create();
    FOutputVolume := TNNetVolume.Create();
    FInputVolume.ReSize(1, 1, InputCount);

    SetupChart;

    StatusBar.SimpleText :=
      'ℹ️ Arrays bereit, Komponenten zugewiesen, Netzwerk erzeugt';
  END;

PROCEDURE TForm1.FormCloseQuery(Sender: TObject; VAR CanClose: BOOLEAN);
  BEGIN
    TimerChartUpdate.Enabled := FALSE;
    IF MessageDlg('Programm beenden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes THEN
      BEGIN
      StatusBar.SimpleText := '❓ Schliessen....?';
        TRY
        chart1.SaveToFile(TJPEGImage,
          ('daten/chart/'+FormatDateTime('YYYYMMDD-HHMMSS', now)+'.jpg'))
        EXCEPT
        ON E: Exception DO
          BEGIN
          ShowMessage(E.Message);
          END;
        END;
      END
    ELSE
      BEGIN
      StatusBar.SimpleText := 'nicht schliessen';
      TimerChartUpdate.Enabled := TRUE;
      CanClose := FALSE;
      END;
  END;

PROCEDURE TForm1.FormDestroy(Sender: TObject);
  VAR
    i: INTEGER;
  BEGIN
    // Timer stoppen, um weitere Aufrufe zu vermeiden
    TimerChartUpdate.Enabled := FALSE;

    // Neuronales Netzwerk freigeben
    IF Assigned(NN) THEN
      FreeAndNil(NN);

    // Ein- und Ausgabe-Volumes freigeben
    IF Assigned(FInputVolume) THEN
      FreeAndNil(FInputVolume);

    IF Assigned(FOutputVolume) THEN
      FreeAndNil(FOutputVolume);

    // Arrays für Eingabe- und Ausgabeseriendaten freigeben
    SetLength(InputData, 0, 0);
    SetLength(OutputData, 0, 0);
    SetLength(NormalizedInputData, 0, 0);
    SetLength(NormalizedOutputData, 0, 0);

    // Min/Max-Arrays freigeben
    SetLength(MinInputs, 0);
    SetLength(MaxInputs, 0);
    SetLength(MinOutputs, 0);
    SetLength(MaxOutputs, 0);

    {TChart-Serien freigeben}

    FOR  i := 0 TO Inputcount DO
      IF Assigned(InputSeries[i]) AND (InputSeries[i].Owner = NIL) THEN
        FreeAndNil(InputSeries[i]);

    FOR  i := 0 TO Outputcount DO
      IF Assigned(OutputSeries[i]) AND (OutputSeries[i].Owner = NIL) THEN
        FreeAndNil(OutputSeries[i]);

    // Arrays für Serienlisten freigeben
    SetLength(InputSeries, 0);
    SetLength(OutputSeries, 0);

    // TrackBar- und Label-Arrays freigeben
    SetLength(InputTrackBars, 0);
    SetLength(InputLabels, 0);
    SetLength(InputValueLabels, 0);

    SetLength(OutputTrackBars, 0);
    SetLength(OutputLabels, 0);
    SetLength(OutputValueLabels, 0);

    // Bereinigen der Protokollierung
    LogMemo.Clear;
    INHERITED;
    // Steht meistens am Ende des Destruktors und startet den Destruktor der Elternklasse
  END;

PROCEDURE TForm1.NormalizeButtonClick(Sender: TObject);
  VAR
    i, j: INTEGER;
    MinValues, MaxValues: ARRAY OF DOUBLE;
  BEGIN
    SetLength(NormalizedInputData, Length(InputData), InputCount);
    SetLength(NormalizedOutputData, Length(OutputData), OutputCount);

    // Daten normalisieren
    FOR i := 0 TO High(InputData) DO
      BEGIN
      FOR j := 0 TO InputCount-1 DO
        NormalizedInputData[i][j] :=
          Normalize(InputData[i][j], MinInputs[j], MaxInputs[j]);

      FOR j := 0 TO OutputCount-1 DO
        NormalizedOutputData[i][j] :=
          Normalize(OutputData[i][j], MinOutputs[j], MaxOutputs[j]);
      END;


    LogMessage('Eingabewerte (Min/Max):');
    FOR j := 0 TO InputCount-1 DO
      LogMessage('  Eingang '+j.ToString+': '+MinInputs[j].ToString+
        ' bis '+MaxInputs[j].ToString);

    LogMessage('Ausgabewerte (Min/Max):');
    FOR j := 0 TO OutputCount-1 DO
      LogMessage('  Ausgang '+j.ToString+': '+MinOutputs[j].ToString+
        ' bis '+MaxOutputs[j].ToString);

    TrainButton.Enabled  := TRUE;
    StatusBar.SimpleText := '✔️ Daten wurden normalisiert';
  END;

PROCEDURE TForm1.TrainButtonClick(Sender: TObject);
  VAR
    vInput, vOutput: TNNetVolume;
    TotalEpochs, Epoch, i, j: INTEGER;
    TrainingError, PreviousError, InitialLearningRate: DOUBLE;
    OutputVolume2:   TNNetVolume;
    CurrentError:    DOUBLE;
    LearningRate:    DOUBLE;
  BEGIN
      TRY
      vInput  := TNNetVolume.Create();
      vOutput := TNNetVolume.Create();
      OutputVolume2 := TNNetVolume.Create();

      IF NOT Assigned(NN) THEN
        BEGIN
        // Fehlermeldung anzeigen
        ShowMessage('Netzwerk nicht initialisiert!');
        Exit;
        END;
      InitialLearningRate := 0.01;
      TotalEpochs := 100;

      // Lernrate setzen, wie in CAI Neural API empfohlen
      LearningRate := InitialLearningRate;
      NN.SetLearningRate(LearningRate, 0.9);

      LogMessage('Starte Training des neuronalen Netzwerks...');
      PreviousError := MaxDouble;

      // Training für mehrere Epochen durchführen
      FOR Epoch := 1 TO TotalEpochs DO
        TRY
        TrainingError := 0;

        // Lernrate anpassen für bessere Konvergenz (optional)
        LearningRate := InitialLearningRate*(1+Cos(PI*Epoch/TotalEpochs))/2;
        NN.SetLearningRate(LearningRate, 0.9);


        // Über alle Datensätze iterieren
        FOR i := 0 TO High(NormalizedInputData) DO
          BEGIN
          // Eingabe- und Ausgabevolumen vorbereiten
          vInput.ReSize(1, 1, InputCount);
          vOutput.ReSize(1, 1, OutputCount);

          // Daten in Volumen kopieren
          FOR j := 0 TO InputCount-1 DO
            vInput.Raw[j] := NormalizedInputData[i][j];

          FOR j := 0 TO OutputCount-1 DO
            vOutput.Raw[j] := NormalizedOutputData[i][j];

          // Feed-Forward und Backpropagation
          NN.Compute(vInput);
          NN.Backpropagate(vOutput);
          NN.GetOutput(OutputVolume2);

          // Berechnung des mittleren quadratischen Fehlers (MSE)
          CurrentError := 0;
          FOR j := 0 TO OutputCount-1 DO
            CurrentError := CurrentError+Sqr(OutputVolume2.Raw[j]-vOutput.Raw[j]);

          // Wenn Sie den Durchschnitt für diesen Datenpunkt möchten
          CurrentError := CurrentError/OutputCount;

          // Addieren Sie diesen Fehler zur Gesamtfehlersumme
          TrainingError := TrainingError+CurrentError;

          NN.UpdateWeights();
          END;

        // Durchschnittlichen Fehler berechnen
        TrainingError := TrainingError/Length(NormalizedInputData);

        // Status nur einmal pro Epoche ausgeben (entfernt doppelte Logging-Einträge)
        IF (Epoch MOD 5 = 0) OR (Epoch = 1) OR (Epoch = TotalEpochs) THEN
          LogMessage('Epoche '+IntToStr(Epoch)+': Fehler = '+
            FloatToStr(TrainingError));

        // Frühzeitiger Abbruch, wenn kaum noch Verbesserung
        IF (PreviousError-TrainingError)<0.00001 THEN
          BEGIN
          LogMessage('Training frühzeitig beendet - Konvergenz erreicht. Epoche: '+
            IntToStr(Epoch));
          Break;
          END;

        // PreviousError nach jeder Epoche aktualisieren (nicht nur alle 2 Epochen)
        PreviousError := TrainingError;

        EXCEPT
        ON E: Exception DO
          BEGIN
          LogMessage('❌ Fehler Training: '+E.Message);
          Exit;
          END;
        END;

      LogMessage('Training abgeschlossen.');

      // Nach dem Training
      // SaveDialog konfigurieren
      SaveDialog.Title      := '💾 Neuronales Netzwerk speichern';
      SaveDialog.DefaultExt := 'nn';
      SaveDialog.Filter     :=
        'Neural Network Dateien (*.nn)|*.nn|Alle Dateien (*.*)|*.*';
      SaveDialog.FilterIndex := 1;
      SaveDialog.Options    := SaveDialog.Options+[ofOverwritePrompt];

      IF SaveDialog.Execute THEN
        TRY
        SaveModelWithMetadata(SaveDialog.Filename,
          ChangeFileExt(SaveDialog.Filename, '.meta'));

        LogMessage('✅ Model Trainiert und mit Metadaten gespeichert in: '+
          SaveDialog.FileName);
        EXCEPT
        ON E: Exception DO
          LogMessage('❌ Fehler beim Speichern des Modells: '+E.Message);
        END;

      PredictionButton.Enabled := TRUE;
      OptimizeButton.Enabled   := TRUE;
      StatusBar.SimpleText     := '✅ Model Trainiert und mit Metadaten gespeichert';

      FINALLY
      vInput.Free;
      vOutput.Free;
      OutputVolume2.Free;
      END;
  END;

PROCEDURE TForm1.SchieberChanged(Sender: TObject);
  VAR
    i: INTEGER;
    NormalizedValue, DenormalizedValue: DOUBLE;
  BEGIN
    // Prüfen, ob das Netzwerk existiert
    IF NOT Assigned(NN) THEN
      BEGIN
      ShowMessage('❌ Netzwerk nicht initialisiert. Bitte zuerst trainieren oder ein Modell laden.');
      Exit;
      END;

    // Eingabevolumen entsprechend der Anzahl der Eingänge dimensionieren, falls nötig
    IF (FInputVolume.Depth<>InputCount) THEN
      FInputVolume.ReSize(1, 1, InputCount);

    // Werte der Eingangsschieber ins Volumen kopieren
    FOR i := 0 TO InputCount-1 DO
      IF InputTrackBars[i]<>NIL THEN
        BEGIN
        // Schieberwert von 0-100 auf Bereich 0-1 normalisieren
        NormalizedValue := InputTrackBars[i].Position/100;

        // Wert ins Eingabevolumen setzen (normalisiert für das Netzwerk)
        FInputVolume.Raw[i] := NormalizedValue;

        // Denormalisierten Wert berechnen und im Label anzeigen
        DenormalizedValue := Denormalize(NormalizedValue, MinInputs[i], MaxInputs[i]);

        // Wert-Label mit denormalisiertem Wert aktualisieren
        IF InputValueLabels[i]<>NIL THEN
          InputValueLabels[i].Caption := FloatToStrF(DenormalizedValue, ffFixed, 6, 2);
        END;

    // Berechnung starten und Zeit messen
    BeginTime := Now();

    // Netzwerkberechnung durchführen
    NN.Compute(FInputVolume);
    NN.GetOutput(FOutputVolume);

    // Berechnungszeit speichern
    FPreviousComputeTime := Now()-BeginTime;

    // Ausgabewerte auf die Ausgangsschieber übertragen
    FOR i := 0 TO OutputCount-1 DO
      IF OutputTrackBars[i]<>NIL THEN
        BEGIN
        // Wert aus der Netzwerkausgabe holen (begrenzen auf 0-1)
        NormalizedValue := Max(0, Min(1, FOutputVolume.Raw[i]));

        // Wert auf den Schieber übertragen (0-100)
        OutputTrackBars[i].Position := Round(NormalizedValue*100);

        // Denormalisierten Wert berechnen
        DenormalizedValue := Denormalize(NormalizedValue, MinOutputs[i], MaxOutputs[i]);

        // Wert-Label mit denormalisiertem Wert aktualisieren
        IF OutputValueLabels[i]<>NIL THEN
          OutputValueLabels[i].Caption := FloatToStrF(DenormalizedValue, ffFixed, 6, 2);
        END;

    // Optional: Status-Informationen aktualisieren
    StatusBar.SimpleText := Format('✅ Berechnung abgeschlossen. Zeit: %s ms.',
      [FormatFloat('0.000', FPreviousComputeTime*24*60*60*1000)]);
  END;

PROCEDURE TForm1.SaveModelWithMetadata(ModelFilename, MetadataFilename: STRING);
  VAR
    IniFile: TIniFile;
    i: INTEGER;
  BEGIN
    // Netzwerk speichern
    NN.SaveToFile(ModelFilename);

    // Metadaten in INI-Datei speichern
    IniFile := TIniFile.Create(MetadataFilename);
      TRY
      IniFile.WriteInteger('Dimensions', 'InputCount', InputCount);
      IniFile.WriteInteger('Dimensions', 'OutputCount', OutputCount);

      // Min/Max für Eingänge
      FOR i := 0 TO InputCount-1 DO
        BEGIN
        IniFile.WriteFloat('InputMinValues', 'Input'+IntToStr(i), MinInputs[i]);
        IniFile.WriteFloat('InputMaxValues', 'Input'+IntToStr(i), MaxInputs[i]);
        END;

      // Min/Max für Ausgänge
      FOR i := 0 TO OutputCount-1 DO
        BEGIN
        IniFile.WriteFloat('OutputMinValues', 'Output'+IntToStr(i), MinOutputs[i]);
        IniFile.WriteFloat('OutputMaxValues', 'Output'+IntToStr(i), MaxOutputs[i]);
        END;
      FINALLY
      IniFile.Free;
      END;
  END;

PROCEDURE TForm1.LoadModelWithMetadata(ModelFilename, MetadataFilename: STRING);
  VAR
    IniFile: TIniFile;
    i: INTEGER;
  BEGIN
    // Netzwerk laden
    IF NN<>NIL THEN NN.Free;
    NN := TNNet.Create();
    NN.LoadFromFile(ModelFilename);

    // Metadaten aus INI-Datei laden
    IniFile := TIniFile.Create(MetadataFilename);
      TRY
      InputCount  := IniFile.ReadInteger('Dimensions', 'InputCount', 0);
      OutputCount := IniFile.ReadInteger('Dimensions', 'OutputCount', 0);

      // Arrays vorbereiten
      SetLength(MinInputs, InputCount);
      SetLength(MaxInputs, InputCount);
      SetLength(MinOutputs, OutputCount);
      SetLength(MaxOutputs, OutputCount);

      // Min/Max für Eingänge
      FOR i := 0 TO InputCount-1 DO
        BEGIN
        MinInputs[i] := IniFile.ReadFloat('InputMinValues', 'Input'+IntToStr(i), 0);
        MaxInputs[i] := IniFile.ReadFloat('InputMaxValues', 'Input'+IntToStr(i), 1);
        END;

      // Min/Max für Ausgänge
      FOR i := 0 TO OutputCount-1 DO
        BEGIN
        MinOutputs[i] := IniFile.ReadFloat('OutputMinValues', 'Output'+IntToStr(i), 0);
        MaxOutputs[i] := IniFile.ReadFloat('OutputMaxValues', 'Output'+IntToStr(i), 1);
        END;
      FINALLY
      IniFile.Free;
      END;
  END;

PROCEDURE TForm1.OptimizeButtonClick(Sender: TObject);
  VAR
    i: INTEGER;
  BEGIN
    LogMemo.Clear;
    // Timer für Grafik freischalten
    TimerChartUpdate.Enabled := TRUE;
    // Prüfen, ob das Netzwerk existiert
    IF NOT Assigned(NN) THEN // NN statt NN
      BEGIN
      ShowMessage('Netzwerk nicht initialisiert. Bitte zuerst trainieren oder ein Modell laden.');
      Exit;
      END;

    // Optimierungsmodus aktivieren

    // Ausgabeschieber aktivieren
    FOR i := 0 TO OutputCount-1 DO
      IF (i<Length(OutputTrackBars)) AND (OutputTrackBars[i]<>NIL) THEN
        BEGIN
        OutputTrackBars[i].Enabled  := TRUE;
        OutputTrackBars[i].OnChange := @OutputSchieberChanged;
        END;

    // Eingabeschieber deaktivieren
    FOR i := 0 TO InputCount-1 DO
      IF (i<Length(InputTrackBars)) AND (InputTrackBars[i]<>NIL) THEN
        InputTrackBars[i].Enabled := FALSE;

    // UI aktualisieren
    //OptimizeButton.Caption := 'Optimierungsmodus';
    StatusBar.SimpleText :=
      '🔄 Optimierungsmodus aktiv. Bewegen Sie einen Ausgangsschieber, um Eingänge zu optimieren.';
    LogMessage('Optimierungsmodus aktiviert. Bewegen Sie einen Ausgangsschieber, um Eingänge zu optimieren.');


    // UI aktualisieren
    OptimizeButton.Enabled   := FALSE;
    PredictionButton.Enabled := TRUE;

    StatusBar.SimpleText :=
      '✅ Vorhersagemodus aktiv. Bewegen Sie die Eingangsschieber, um Ausgänge zu berechnen.';
    //LogMessage('Optimierungsmodus deaktiviert. Zurück im normalen Vorhersagemodus.');
  END;

PROCEDURE TForm1.InputTrackBarClick(Sender: TObject);
  VAR
    i: INTEGER;
  BEGIN
    ClickInputIdx := -1;
    FOR i := 0 TO InputCount-1 DO
      IF (i<Length(InputTrackBars)) AND (InputTrackBars[i] = Sender) THEN
        BEGIN
        ClickInputIdx := i;
        Break;
        END;
  END;

PROCEDURE TForm1.OutputTrackBarClick(Sender: TObject);
  VAR
    i: INTEGER;
  BEGIN
    ClickOutputIdx := -1;
    FOR i := 0 TO OutputCount-1 DO
      IF (i<Length(OutputTrackBars)) AND (OutputTrackBars[i] = Sender) THEN
        BEGIN
        ClickOutputIdx := i;
        Break;
        END;
  END;

PROCEDURE TForm1.OutputSchieberChanged(Sender: TObject);
  CONST
    // Optimierungsparameter
    MAX_ITERATIONS = 1000;       // Maximale Iterationen
    LEARNING_RATE = 0.1;         // Lernrate für Gradient Descent
    ERROR_THRESHOLD = 0.0001;    // Schwellwert für frühzeitigen Abbruch
    MOMENTUM = 0.9;              // Momentum für stabilere Konvergen
  VAR
    TargetOutput:  TNNetVolume;      // Zielausgabe aus den Schiebereglern
    CurrentInput:  TNNetVolume;      // Aktuelle Eingabewerte
    BestInput:     TNNetVolume;      // Beste gefundene Eingabewerte
    GradientInput: TNNetVolume;      // Gradient für die Eingabewerte
    PreviousGradient: TNNetVolume;   // Vorheriger Gradient (für Momentum)
    TempOutput:    TNNetVolume;      // Temporäre Ausgabe für Berechnungen

    i, j, Iteration: INTEGER;
    Error, BestError, CurrentError, PrevError: DOUBLE;
    NormalizedValue, DenormalizedValue: DOUBLE;
    MovedOutputIdx: INTEGER;
    DELTA: DOUBLE;
  BEGIN
    // Sicherstellen, dass Sender ein TTrackBar ist
    IF NOT (Sender IS TTrackBar) THEN Exit;


    MovedOutputIdx := -1;
    FOR i := 0 TO OutputCount-1 DO
      // Den Index des bewegten Schiebereglers finden
      IF (i<Length(OutputTrackBars)) AND (OutputTrackBars[i] = Sender) THEN
        BEGIN
        MovedOutputIdx := i;
        Break;
        END;

    // Sicherstellen, dass wir einen gültigen Schieberegler gefunden haben
    IF MovedOutputIdx<0 THEN Exit;

    // Log-Nachricht zum Start der Optimierung
    LogMessage('Starte Optimierung für Ausgang '+IntToStr(MovedOutputIdx+1)+
      ' mit Zielwert: '+OutputValueLabels[MovedOutputIdx].Caption);

    // Volumen für die Optimierung erstellen
    TargetOutput  := TNNetVolume.Create(1, 1, OutputCount);
    CurrentInput  := TNNetVolume.Create(1, 1, InputCount);
    BestInput     := TNNetVolume.Create(1, 1, InputCount);
    GradientInput := TNNetVolume.Create(1, 1, InputCount);
    PreviousGradient := TNNetVolume.Create(1, 1, InputCount);
    TempOutput    := TNNetVolume.Create(1, 1, OutputCount);

      TRY
      // Zielausgabe aus den Schiebereglern setzen
      FOR i := 0 TO OutputCount-1 DO
        IF (i<Length(OutputTrackBars)) AND (OutputTrackBars[i]<>NIL) THEN
          BEGIN
          // Normalisierter Wert (0-1)
          NormalizedValue     := OutputTrackBars[i].Position/100.0;
          TargetOutput.Raw[i] := NormalizedValue;
          END;

      // Initialisierung mit den aktuellen Eingabewerten statt zufälligen Werten
      FOR i := 0 TO InputCount-1 DO
        BEGIN
        IF (i<Length(InputTrackBars)) AND (InputTrackBars[i]<>NIL) THEN
          CurrentInput.Raw[i] :=
            InputTrackBars[i].Position/100.0
        // Aktuellen Wert vom Schieberegler als Startwert verwenden

        ELSE
          CurrentInput.Raw[i] := Random; // zufälligen Wert, falls kein Schieberegler
        BestInput.Raw[i] := CurrentInput.Raw[i];
        GradientInput.Raw[i]    := 0;
        PreviousGradient.Raw[i] := 0;
        END;

      // Startfehler berechnen
      NN.Compute(CurrentInput);
      NN.GetOutput(TempOutput);

      // Nur den bewegten Ausgang optimieren
      BestError := Sqr(TempOutput.Raw[MovedOutputIdx]-TargetOutput.Raw[MovedOutputIdx]);

      // Hauptoptimierungsschleife (Gradient Descent)
      Iteration := 0;
      PrevError := MaxDouble;

      WHILE (Iteration<MAX_ITERATIONS) DO
        BEGIN
        // Vorwärtsdurchlauf für aktuelle Eingabe
        NN.Compute(CurrentInput);
        NN.GetOutput(TempOutput);

        // Aktuellen Fehler berechnen - NUR für den bewegten Ausgang
        CurrentError := Sqr(TempOutput.Raw[MovedOutputIdx]-
          TargetOutput.Raw[MovedOutputIdx]);

        // Status alle 50 Iterationen anzeigen
        IF Iteration MOD 50 = 0 THEN
          LogMessage('Iteration '+IntToStr(Iteration)+': Fehler = '+
            FloatToStr(CurrentError));

        // Beste Lösung merken
        IF CurrentError<BestError THEN
          BEGIN
          BestError := CurrentError;
          FOR i := 0 TO InputCount-1 DO
            BestInput.Raw[i] := CurrentInput.Raw[i];

          // Wenn Fehler klein genug ist, frühzeitig abbrechen
          IF BestError<ERROR_THRESHOLD THEN
            BEGIN
            LogMessage('Optimierung erfolgreich abgeschlossen! Fehler: '+
              FloatToStr(BestError));
            Break;
            END;
          END;

        // Abbruch, wenn keine Verbesserung mehr
        IF Abs(PrevError-CurrentError)<0.00001*(1+CurrentError) THEN
          BEGIN
          LogMessage('Keine weitere Verbesserung möglich. Optimierung beendet.');
          Break;
          END;

        PrevError := CurrentError;

        // Gradient für jede Eingabevariable berechnen mittels numerischer Differentiation
        FOR i := 0 TO InputCount-1 DO
          BEGIN
          // Kleine Änderung für numerische Ableitung
          DELTA := 0.001;

          // Vorwärtswert speichern
          Error := CurrentError;

          // Wert leicht erhöhen und Fehler neu berechnen
          CurrentInput.Raw[i] := CurrentInput.Raw[i]+DELTA;
          NN.Compute(CurrentInput);  // NN statt NN
          NN.GetOutput(TempOutput);

          // Neuen Fehler berechnen - NUR für den bewegten Ausgang
          CurrentError := Sqr(TempOutput.Raw[MovedOutputIdx]-
            TargetOutput.Raw[MovedOutputIdx]);

          // Gradient als Differenz der Fehler geteilt durch Delta
          GradientInput.Raw[i] := (CurrentError-Error)/DELTA;

          // Wert zurücksetzen
          CurrentInput.Raw[i] := CurrentInput.Raw[i]-DELTA;
          END;

        // Eingabewerte mit Gradient Descent aktualisieren (mit Momentum)
        FOR i := 0 TO InputCount-1 DO
          BEGIN
          // Gradient Descent mit Momentum
          PreviousGradient.Raw[i] :=
            MOMENTUM*PreviousGradient.Raw[i]-LEARNING_RATE*
            GradientInput.Raw[i];

          // Eingabewert aktualisieren
          CurrentInput.Raw[i] := CurrentInput.Raw[i]+PreviousGradient.Raw[i];

          // Eingabewerte auf 0-1 beschränken
          CurrentInput.Raw[i] := Max(0, Min(1, CurrentInput.Raw[i]));
          END;

        Inc(Iteration);
        END;

      // Beste gefundene Eingabewerte auf die Eingangsschieber übertragen
      FOR i := 0 TO InputCount-1 DO
        IF (i<Length(InputTrackBars)) AND (InputTrackBars[i]<>NIL) THEN
          BEGIN
          // Normalisierter Wert (0-1) auf Schieber (0-100) übertragen
          InputTrackBars[i].Position := Round(BestInput.Raw[i]*100);

          // Denormalisierten Wert berechnen (falls eine Denormalize-Funktion existiert)
          IF @Denormalize<>NIL THEN
            DenormalizedValue :=
              Denormalize(BestInput.Raw[i], MinInputs[i], MaxInputs[i])
          ELSE
            DenormalizedValue := BestInput.Raw[i]; // Fallback

          // Wert-Label mit denormalisiertem Wert aktualisieren
          IF (i<Length(InputValueLabels)) AND (InputValueLabels[i]<>NIL) THEN
            InputValueLabels[i].Caption := FloatToStrF(DenormalizedValue, ffFixed, 6, 2);
          END;

      // Berechnung durchführen, um alle Ausgänge zu aktualisieren
      NN.Compute(BestInput);
      NN.GetOutput(TempOutput);

      // Alle Ausgänge aktualisieren, ausser den gerade optimierten
      FOR i := 0 TO OutputCount-1 DO
        IF (i<>MovedOutputIdx) AND (i<Length(OutputTrackBars)) AND
          (OutputTrackBars[i]<>NIL) THEN
          BEGIN
          // OnChange-Event blockieren, um Endlosschleife zu vermeiden
          OutputTrackBars[i].OnChange := NIL;
          OutputTrackBars[i].Position := Round(TempOutput.Raw[i]*100);
          OutputTrackBars[i].OnChange := @OutputSchieberChanged;

          // Denormalisierten Wert berechnen
          IF @Denormalize<>NIL THEN
            DenormalizedValue :=
              Denormalize(TempOutput.Raw[i], MinOutputs[i], MaxOutputs[i])
          ELSE
            DenormalizedValue := TempOutput.Raw[i]; // Fallback

          // Wert-Label mit denormalisiertem Wert aktualisieren
          IF (i<Length(OutputValueLabels)) AND (OutputValueLabels[i]<>NIL) THEN
            OutputValueLabels[i].Caption :=
              FloatToStrF(DenormalizedValue, ffFixed, 6, 2);
          END;

      // Optimierungsergebnis ausgeben
      LogMessage('Optimierung abgeschlossen! Gefundener Fehler: '+FloatToStr(BestError));


      // Status-Nachricht aktualisieren
      StatusBar.SimpleText :=
        'ℹ️ ptimierung abgeschlossen. Die Eingangswerte wurden optimiert.';

      FINALLY
      // Aufräumen
      TargetOutput.Free;
      CurrentInput.Free;
      BestInput.Free;
      GradientInput.Free;
      PreviousGradient.Free;
      TempOutput.Free;
      END;
  END;

END.
