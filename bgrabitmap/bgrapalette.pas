unit BGRAPalette;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, AvgLvlTree, BGRABitmapTypes, FPimage;

const
  MaxLastAddedColors = 10;

type
  TBGRAPaletteFormat = integer;

const
  palUnknown : TBGRAPaletteFormat = 0;
  palPaintDotNet : TBGRAPaletteFormat = 1;
  palGimp : TBGRAPaletteFormat = 2;
  palAdobeSwatchExchange : TBGRAPaletteFormat = 3;
  palKOffice : TBGRAPaletteFormat = 4;
  palJascPSP : TBGRAPaletteFormat = 5;
  palCustom : TBGRAPaletteFormat = 100;

type
  TBGRAWeightedPaletteEntry = packed record
    Color: TBGRAPixel;
    Weight: UInt32;
  end;
  PBGRAWeightedPaletteEntry = ^TBGRAWeightedPaletteEntry;
  ArrayOfWeightedColor = array of TBGRAWeightedPaletteEntry;

  { TBGRACustomPalette }

  TBGRACustomPalette = class
  protected
    function GetCount: integer; virtual; abstract;
    function GetColorByIndex(AIndex: integer): TBGRAPixel; virtual; abstract;
  public
    function ContainsColor(AValue: TBGRAPixel): boolean; virtual; abstract;
    function IndexOfColor(AValue: TBGRAPixel): integer; virtual; abstract;
    function GetAsArrayOfColor: ArrayOfTBGRAPixel; virtual; abstract;
    function GetAsArrayOfWeightedColor: ArrayOfWeightedColor; virtual; abstract;
    procedure AssignTo(AImage: TFPCustomImage); overload;
    procedure AssignTo(APalette: TFPPalette); overload;
    property Count: integer read GetCount;
    property Color[AIndex: integer]: TBGRAPixel read GetColorByIndex;
  end;

  { TBGRAAvgLvlPalette }

  TBGRAAvgLvlPalette = class(TBGRACustomPalette)
  protected
    FTree: TAvgLvlTree;
    FArray: array of PBGRAPixel;
    FLastAddedColors: packed array[0..MaxLastAddedColors-1] of PBGRAPixel;
    FLastAddedColorCount: integer;
    function GetCount: integer; override;
    function GetColorByIndex(AIndex: integer): TBGRAPixel; override;
    function OnCompareItems({%H-}Tree: TAvgLvlTree; Data1, Data2: Pointer): integer; virtual;
    procedure FreeEntry(AEntry: PBGRAPixel); virtual; abstract;
    procedure NeedArray; virtual;
    procedure ClearArray; virtual;
    procedure AddLastColor(AColor: PBGRAPixel);
    function GetLastColor(AValue: TBGRAPixel): PBGRAPixel;
    procedure ClearLastColors;
  public
    constructor Create; overload;
    function ContainsColor(AValue: TBGRAPixel): boolean; override;
    function IndexOfColor(AValue: TBGRAPixel): integer; override;
    procedure Clear; virtual;
    destructor Destroy; override;
    function GetAsArrayOfColor: ArrayOfTBGRAPixel; override;
    function GetAsArrayOfWeightedColor: ArrayOfWeightedColor; override;
  end;

  { TBGRAPalette }

  TBGRAPalette = class(TBGRAAvgLvlPalette)
  protected
    function CreateEntry(AColor: TBGRAPixel): PBGRAPixel; virtual;
    procedure FreeEntry(AEntry: PBGRAPixel); override;
    procedure IncludePixel(PPixel: PBGRAPixel); virtual;
    procedure ExceptionUnknownPaletteFormat;
    procedure ExceptionInvalidPaletteFormat;
  public
    constructor Create(ABitmap: TBGRACustomBitmap); virtual; overload;
    function AddColor(AValue: TBGRAPixel): boolean; virtual;
    function RemoveColor(AValue: TBGRAPixel): boolean; virtual;
    procedure LoadFromFile(AFilenameUTF8: string); virtual;
    procedure LoadFromStream(AStream: TStream; AFormat: TBGRAPaletteFormat); virtual;
    procedure SaveToFile(AFilenameUTF8: string); virtual;
    procedure SaveToStream(AStream: TStream; AFormat: TBGRAPaletteFormat); virtual;
    function DetectPaletteFormat(AStream: TStream): TBGRAPaletteFormat; virtual;
    function DetectPaletteFormat(AFilenameUTF8: string): TBGRAPaletteFormat;
    function SuggestPaletteFormat(AFilenameUTF8: string): TBGRAPaletteFormat; virtual;
  end;

  { TBGRAWeightedPalette }

  TBGRAWeightedPalette = class(TBGRAPalette)
  private
  protected
    function CreateEntry(AColor: TBGRAPixel): PBGRAPixel; override;
    procedure FreeEntry(AEntry: PBGRAPixel); override;
    function GetWeightByIndex(AIndex: Integer): UInt32; virtual;
    procedure IncludePixel(PPixel: PBGRAPixel); override;
  public
    function GetAsArrayOfWeightedColor: ArrayOfWeightedColor; override;
    function IncColor(AValue: TBGRAPixel; out NewWeight: UInt32): boolean;
    function DecColor(AValue: TBGRAPixel; out NewWeight: UInt32): boolean;
    property Weight[AIndex: Integer]: UInt32 read GetWeightByIndex;
  end;

  { TBGRAReferencePalette }

  TBGRAReferencePalette = class(TBGRAAvgLvlPalette)
  protected
    procedure FreeEntry({%H-}AEntry: PBGRAPixel); override;
  public
    function AddColor(AValue: PBGRAPixel): boolean;
    function RemoveColor(AValue: PBGRAPixel): boolean;
  end;

  { TBGRACustomApproxPalette }

  TBGRACustomApproxPalette = class(TBGRACustomPalette)
  private
    function FindNearestColorIgnoreAlpha(AValue: TBGRAPixel): TBGRAPixel;
  public
    function FindNearestColor(AValue: TBGRAPixel; AIgnoreAlpha: boolean): TBGRAPixel; overload;
    function FindNearestColor(AValue: TBGRAPixel): TBGRAPixel; virtual; abstract;
    function FindNearestColorIndex(AValue: TBGRAPixel): integer; virtual; abstract;
  end;

function BGRARequiredBitDepth(ABitmap: TBGRACustomBitmap; AAlpha: TAlphaChannelPaletteOption): integer; overload;
function BGRARequiredBitDepth(APalette: TBGRACustomPalette): integer; overload;

type
  TPaletteReaderProc = function(APalette: TBGRAPalette; AStream: TStream): boolean;
  TPaletteWriterProc = procedure(APalette: TBGRAPalette; AStream: TStream);
  TCheckPaletteFormatProc = function(ABuf256: string): boolean;

procedure BGRARegisterPaletteFormat(AFormatIndex: TBGRAPaletteFormat; AExtension: string; ADescription: string;
  AReadProc: TPaletteReaderProc; AWriteProc: TPaletteWriterProc; ACheckFormatProc: TCheckPaletteFormatProc);
function BGRARegisteredPaletteFormatFilter(AAllSupportedDescription: string) : string;

implementation

uses lazutf8classes, bufstream;

{$i paletteformats.inc}

function BGRARequiredBitDepth(ABitmap: TBGRACustomBitmap; AAlpha: TAlphaChannelPaletteOption): integer;
var
  palette: TBGRAPalette;
  p: PBGRAPixel;
  i: NativeInt;
  transparentEntry: boolean;
begin
  palette := TBGRAPalette.Create;
  p := ABitmap.Data;
  transparentEntry := false;
  if AAlpha = acIgnore then
  begin
    for i := ABitmap.NbPixels-1 downto 0 do
    begin
      palette.AddColor(BGRA(p^.red,p^.green,p^.blue));
      inc(p);
      if palette.Count > 256 then break;
    end;
  end else
  if AAlpha = acTransparentEntry then
  begin
    for i := ABitmap.NbPixels-1 downto 0 do
    begin
      if p^.alpha < 128 then
        transparentEntry:= true
      else
        palette.AddColor(BGRA(p^.red,p^.green,p^.blue));
      inc(p);
      if palette.Count > 256 then break;
    end;
  end else
  begin
    for i := ABitmap.NbPixels-1 downto 0 do
    begin
      palette.AddColor(p^);
      inc(p);
      if palette.Count > 256 then break;
    end;
  end;

  if palette.Count+byte(transparentEntry) > 256 then
  begin
    if (AAlpha = acFullChannelInPalette) and ABitmap.HasTransparentPixels then
      result := 32
    else
    if (AAlpha = acTransparentEntry) and ABitmap.HasTransparentPixels then
      result := 25
    else
      result := 24;
  end else
  begin
    result := 8;
    while (result > 0) and (1 shl (result shr 1) >= palette.Count) do result := result shr 1;
  end;
  palette.Free;
end;

function BGRARequiredBitDepth(APalette: TBGRACustomPalette): integer;
var i: integer;
  hasTransp: boolean;
begin
  if APalette.Count > 256 then
  begin
    hasTransp := false;
    for i := 0 to APalette.Count-1 do
      if APalette.Color[i].alpha <> 255 then
      begin
        hasTransp:= true;
        break;
      end;
    if hasTransp then
      result := 32
    else
      result := 24;
  end else
  begin
    result := 8;
    while (result > 0) and (1 shl (result shr 1) >= APalette.Count) do result := result shr 1;
  end;
end;

{ TBGRACustomPalette }

procedure TBGRACustomPalette.AssignTo(AImage: TFPCustomImage);
begin
  AImage.UsePalette := true;
  AssignTo(AImage.Palette);
end;

procedure TBGRACustomPalette.AssignTo(APalette: TFPPalette);
var i: integer;
begin
  APalette.Clear;
  APalette.Capacity := Count;
  for i := 0 to Count-1 do
    APalette.Color[i] := BGRAToFPColor(Color[i]);
end;

{ TBGRACustomApproxPalette }

function TBGRACustomApproxPalette.FindNearestColorIgnoreAlpha(AValue: TBGRAPixel
  ): TBGRAPixel;
const AlphaMask : DWord = {$IFDEF ENDIAN_LITTLE}$ff000000{$ELSE}$000000ff{$endif};
begin
  if AValue.alpha = 0 then
    result := BGRAPixelTransparent
  else
  begin
    result := FindNearestColor(TBGRAPixel(DWord(AValue) or AlphaMask));
    result.alpha := AValue.alpha;
  end;
end;

function TBGRACustomApproxPalette.FindNearestColor(AValue: TBGRAPixel; AIgnoreAlpha: boolean): TBGRAPixel;
begin
  if AIgnoreAlpha then
    result := FindNearestColorIgnoreAlpha(AValue)
  else
    result := FindNearestColor(AValue);
end;

{ TBGRAWeightedPalette }

function TBGRAWeightedPalette.GetWeightByIndex(AIndex: integer): UInt32;
begin
  NeedArray;
  if (AIndex >= 0) and (AIndex < length(FArray)) then
    result := PBGRAWeightedPaletteEntry(FArray[AIndex])^.Weight
  else
    raise ERangeError.Create('Index out of bounds');
end;

procedure TBGRAWeightedPalette.IncludePixel(PPixel: PBGRAPixel);
var dummy: UInt32;
begin
  IncColor(PPixel^,dummy);
end;

function TBGRAWeightedPalette.GetAsArrayOfWeightedColor: ArrayOfWeightedColor;
var
  i: NativeInt;
begin
  NeedArray;
  setlength(result, length(FArray));
  for i := 0 to high(result) do
    result[i] := PBGRAWeightedPaletteEntry(FArray[i])^;
end;

function TBGRAWeightedPalette.CreateEntry(AColor: TBGRAPixel): PBGRAPixel;
begin
  result := PBGRAPixel(GetMem(sizeOf(TBGRAWeightedPaletteEntry)));
  result^ := AColor;
  PBGRAWeightedPaletteEntry(result)^.Weight := 1;
end;

procedure TBGRAWeightedPalette.FreeEntry(AEntry: PBGRAPixel);
begin
  FreeMem(AEntry);
end;

function TBGRAWeightedPalette.IncColor(AValue: TBGRAPixel; out NewWeight: UInt32
  ): boolean;
Var Node: TAvgLvlTreeNode;
  Entry: PBGRAPixel;
begin
  Entry := GetLastColor(AValue);
  if Entry <> nil then
  begin
    NewWeight := PBGRAWeightedPaletteEntry(Entry)^.Weight+1;
    PBGRAWeightedPaletteEntry(Entry)^.Weight := NewWeight;
    result := false;
    exit;
  end;
  Node := FTree.Find(@AValue);
  if Assigned(Node) then
  begin
    Entry := PBGRAPixel(Node.Data);
    NewWeight := PBGRAWeightedPaletteEntry(Entry)^.Weight+1;
    PBGRAWeightedPaletteEntry(Entry)^.Weight := NewWeight;
    AddLastColor(Entry);
    result := false;
  end
  else
  begin
    Entry := CreateEntry(AValue);
    FTree.Add(Entry);
    ClearArray;
    NewWeight := PBGRAWeightedPaletteEntry(Entry)^.Weight;
    AddLastColor(Entry);
    result := true;
  end;
end;

function TBGRAWeightedPalette.DecColor(AValue: TBGRAPixel; out NewWeight: UInt32
  ): boolean;
var
  Node : TAvgLvlTreeNode;
  Entry: PBGRAPixel;
begin
  Node := FTree.Find(@AValue);
  if Assigned(Node) then
  begin
    Entry := PBGRAPixel(Node.Data);
    NewWeight := PBGRAWeightedPaletteEntry(Entry)^.Weight;
    if NewWeight >= 2 then
    begin
      dec(NewWeight);
      PBGRAWeightedPaletteEntry(Entry)^.Weight := NewWeight;
    end
    else
    begin
      NewWeight := 0;
      FreeEntry(Entry);
      FTree.Delete(Node);
      ClearArray;
      ClearLastColors;
    end;
    result := true;
  end else
  begin
    result := false;
    NewWeight := 0;
  end;
end;

{ TBGRAReferencePalette }

procedure TBGRAReferencePalette.FreeEntry(AEntry: PBGRAPixel);
begin
  //nothing
end;

function TBGRAReferencePalette.AddColor(AValue: PBGRAPixel): boolean;
begin
  if Assigned(GetLastColor(AValue^)) then
  begin
    result := false;
    exit;
  end;
  AddLastColor(AValue);
  if Assigned(FTree.Find(AValue)) then
  begin
    result := false;
  end
  else
  begin
    result := true;
    FTree.Add(AValue);
    ClearArray;
  end;
end;

function TBGRAReferencePalette.RemoveColor(AValue: PBGRAPixel): boolean;
var
  Node : TAvgLvlTreeNode;
begin
  Node := FTree.Find(AValue);
  if Assigned(Node) then
  begin
    FTree.Delete(Node);
    result := true;
    ClearArray;
    ClearLastColors;
  end else
    result := false;
end;

{ TBGRAAvgLvlPalette }

constructor TBGRAAvgLvlPalette.Create;
begin
  FTree := TAvgLvlTree.Create;
  FTree.OnObjectCompare := @OnCompareItems;
end;

destructor TBGRAAvgLvlPalette.Destroy;
begin
  Clear;
  FreeAndNil(FTree);
  inherited Destroy;
end;

function TBGRAAvgLvlPalette.GetAsArrayOfColor: ArrayOfTBGRAPixel;
var i: NativeInt;
begin
  NeedArray;
  setlength(result, Length(FArray));
  for i := 0 to high(result) do
    result[i] := FArray[i]^;
end;

function TBGRAAvgLvlPalette.GetAsArrayOfWeightedColor: ArrayOfWeightedColor;
var i: NativeInt;
begin
  NeedArray;
  setlength(result, Length(FArray));
  for i := 0 to high(result) do
  with result[i] do
  begin
    Color := FArray[i]^;
    Weight:= 1;
  end;
end;

procedure TBGRAAvgLvlPalette.Clear;
var Node: TAvgLvlTreeNode;
begin
  For Node in FTree do
    FreeEntry(PBGRAPixel(Node.Data));
  FTree.Clear;
  ClearArray;
  FLastAddedColorCount := 0;
end;

function TBGRAAvgLvlPalette.GetCount: integer;
begin
  result := FTree.Count;
end;

function TBGRAAvgLvlPalette.ContainsColor(AValue: TBGRAPixel): boolean;
Var Node: TAvgLvlTreeNode;
begin
  if Assigned(GetLastColor(AValue)) then
  begin
    result := true;
    exit;
  end;
  Node := FTree.Find(@AValue);
  result := Assigned(Node);
  if result then AddLastColor(PBGRAPixel(Node.Data));
end;

function TBGRAAvgLvlPalette.IndexOfColor(AValue: TBGRAPixel): integer;
Var Node: TAvgLvlTreeNode;
begin
  Node := FTree.Find(@AValue);
  if Assigned(Node) then
  begin
    result := 0;
    Node := Node.Precessor;
    while Assigned(Node) do
    begin
      inc(result);
      Node := Node.Precessor;
    end;
  end else
    result := -1;
end;

function TBGRAAvgLvlPalette.GetColorByIndex(AIndex: integer): TBGRAPixel;
begin
  NeedArray;
  if (AIndex >= 0) and (AIndex < length(FArray)) then
    result := FArray[AIndex]^
  else
    raise ERangeError.Create('Index out of bounds');
end;

function TBGRAAvgLvlPalette.OnCompareItems(Tree: TAvgLvlTree; Data1, Data2: Pointer): integer;
var gray1, gray2: NativeUInt;
  c1, c2: TBGRAPixel;
begin
  c1 := PBGRAPixel(Data1)^;
  c2 := PBGRAPixel(Data2)^;
  if c1.alpha < c2.alpha then
    result := -1
  else if c1.alpha > c2.alpha then
    result := 1
  else
  begin
    gray1 := (GammaExpansionTab[c1.red] shl 8)+(GammaExpansionTab[c1.green] shl 9)+(GammaExpansionTab[c1.blue] shl 7);
    gray2 := (GammaExpansionTab[c2.red] shl 8)+(GammaExpansionTab[c2.green] shl 9)+(GammaExpansionTab[c2.blue] shl 7);
    if gray1<gray2 then
      result := -1
    else if gray1>gray2 then
      result := 1
    else
    begin
      if c1.green > c2.green then
        result := 1
      else if c1.green < c2.green then
        result := -1
      else if c1.red > c2.red then
        result := 1
      else if c1.red < c2.red then
        result := -1
      else if c1.blue > c2.blue then
        result := 1
      else if c1.blue < c2.blue then
        result := -1
      else
        result := 0;
    end;
  end;
end;

procedure TBGRAAvgLvlPalette.NeedArray;
var Node: TAvgLvlTreeNode;
  i,n: integer;
begin
  n := Count;
  if length(FArray) <> n then
  begin
    setLength(FArray,n);
    i := 0;
    for Node in FTree do
    begin
      if i >= n then break;
      FArray[i] := PBGRAPixel(Node.Data);
      inc(i);
    end;
  end;
end;

procedure TBGRAAvgLvlPalette.ClearArray;
begin
  FArray := nil;
end;

procedure TBGRAAvgLvlPalette.AddLastColor(AColor: PBGRAPixel);
begin
  if FLastAddedColorCount < MaxLastAddedColors then
  begin
    FLastAddedColors[FLastAddedColorCount] := AColor;
    inc(FLastAddedColorCount);
  end else
  begin
    move(FLastAddedColors[1],FLastAddedColors[0],(FLastAddedColorCount-1)*sizeof(PBGRAPixel));
    FLastAddedColors[FLastAddedColorCount-1] := AColor;
  end;
end;

function TBGRAAvgLvlPalette.GetLastColor(AValue: TBGRAPixel): PBGRAPixel;
var
  i: NativeInt;
begin
  for i := FLastAddedColorCount-1 downto 0 do
    if PDWord(FLastAddedColors[i])^ = DWord(AValue) then
    begin
      result := FLastAddedColors[i];
      exit;
    end;
  result := nil;
end;

procedure TBGRAAvgLvlPalette.ClearLastColors;
begin
  FLastAddedColorCount := 0;
end;

{ TBGRAPalette }

function TBGRAPalette.CreateEntry(AColor: TBGRAPixel): PBGRAPixel;
begin
  result := PBGRAPixel(GetMem(sizeOf(TBGRAPixel)));
  result^ := AColor;
end;

procedure TBGRAPalette.FreeEntry(AEntry: PBGRAPixel);
begin
  FreeMem(AEntry);
end;

procedure TBGRAPalette.IncludePixel(PPixel: PBGRAPixel);
begin
  AddColor(PPixel^);
end;

procedure TBGRAPalette.ExceptionUnknownPaletteFormat;
begin
  raise Exception.Create('Unknown palette format');
end;

procedure TBGRAPalette.ExceptionInvalidPaletteFormat;
begin
  raise Exception.Create('Invalid palette format');
end;

constructor TBGRAPalette.Create(ABitmap: TBGRACustomBitmap);
var p: PBGRAPixel;
  n: integer;
begin
  inherited Create;
  n:= ABitmap.NbPixels;
  p := ABitmap.Data;
  while n > 0 do
  begin
    IncludePixel(p);
    inc(p);
    dec(n);
  end;
end;

function TBGRAPalette.AddColor(AValue: TBGRAPixel): boolean;
Var Node: TAvgLvlTreeNode;
  Entry: PBGRAPixel;
begin
  if Assigned(GetLastColor(AValue)) then
  begin
    result := false;
    exit;
  end;
  Node := FTree.Find(@AValue);
  if Assigned(Node) then
  begin
    AddLastColor(PBGRAPixel(Node.Data));
    result := false;
  end
  else
  begin
    result := true;
    Entry := CreateEntry(AValue);
    FTree.Add(Entry);
    ClearArray;
    AddLastColor(Entry);
  end;
end;

function TBGRAPalette.RemoveColor(AValue: TBGRAPixel): boolean;
var
  Node : TAvgLvlTreeNode;
begin
  Node := FTree.Find(@AValue);
  if Assigned(Node) then
  begin
    FreeEntry(Node.Data);
    FTree.Delete(Node);
    result := true;
    ClearArray;
    ClearLastColors;
  end else
    result := false;
end;

procedure TBGRAPalette.LoadFromFile(AFilenameUTF8: string);
var
  stream: TFileStreamUTF8;
  format: TBGRAPaletteFormat;
begin
  format := DetectPaletteFormat(AFilenameUTF8);
  if format = palUnknown then
  begin
    ExceptionUnknownPaletteFormat;
    exit;
  end;
  stream:= TFileStreamUTF8.Create(AFilenameUTF8,fmOpenRead);
  try
    LoadFromStream(stream, format);
  finally
    stream.Free;
  end;
end;

procedure TBGRAPalette.LoadFromStream(AStream: TStream;
  AFormat: TBGRAPaletteFormat);
var buf: TReadBufStream;
  handled: boolean;
  i: Integer;
begin
  RegisterDefaultPaletteFormats;
  Clear;
  buf := TReadBufStream.Create(AStream);
  try
    handled := false;
    for i := 0 to High(PaletteFormats) do
      if PaletteFormats[i].formatIndex = AFormat then
      begin
        if not PaletteFormats[i].reader(self, AStream) then
          ExceptionInvalidPaletteFormat;
        handled := true;
        break;
      end;
    if not handled then ExceptionUnknownPaletteFormat;
  finally
    buf.Free;
  end;
end;

procedure TBGRAPalette.SaveToFile(AFilenameUTF8: string);
var
  stream: TFileStreamUTF8;
begin
  stream:= TFileStreamUTF8.Create(AFilenameUTF8,fmCreate);
  try
    SaveToStream(stream, SuggestPaletteFormat(AFilenameUTF8));
  finally
    stream.Free;
  end;
end;

procedure TBGRAPalette.SaveToStream(AStream: TStream;
  AFormat: TBGRAPaletteFormat);
var buf: TWriteBufStream;
  handled: boolean;
  i: Integer;
begin
  RegisterDefaultPaletteFormats;
  buf := TWriteBufStream.Create(AStream);
  try
    handled := false;
    for i := 0 to High(PaletteFormats) do
      if PaletteFormats[i].formatIndex = AFormat then
      begin
        PaletteFormats[i].writer(self, AStream);
        handled := true;
        break;
      end;
    if not handled then ExceptionUnknownPaletteFormat;
  finally
    buf.Free;
  end;
end;

function TBGRAPalette.DetectPaletteFormat(AStream: TStream): TBGRAPaletteFormat;
var buf: string;
  oldPos: int64;
  i: Integer;
begin
  result := palUnknown;
  setlength(buf,256);
  fillchar(buf[1],length(buf),#0);
  oldPos := AStream.Position;
  AStream.Read(buf[1],length(buf));
  AStream.Position := oldPos;
  if length(buf)>0 then
  begin
    RegisterDefaultPaletteFormats;
    for i := 0 to high(PaletteFormats) do
      if PaletteFormats[i].checkFormat(buf) then
      begin
        result := PaletteFormats[i].formatIndex;
        exit;
      end;
  end;
end;

function TBGRAPalette.DetectPaletteFormat(AFilenameUTF8: string
  ): TBGRAPaletteFormat;
var stream: TFileStreamUTF8;
begin
  result := SuggestPaletteFormat(AFilenameUTF8);
  if not FileExists(AFilenameUTF8) then exit;
  try
    stream := TFileStreamUTF8.Create(AFilenameUTF8,fmOpenRead or fmShareDenyWrite);
  except
    exit;
  end;
  try
    result := DetectPaletteFormat(stream);
    if result = palUnknown then
      result := SuggestPaletteFormat(AFilenameUTF8);
  finally
    stream.Free;
  end;
end;

function TBGRAPalette.SuggestPaletteFormat(AFilenameUTF8: string
  ): TBGRAPaletteFormat;
var ext: string;
  i: Integer;
begin
  RegisterDefaultPaletteFormats;
  ext := ExtractFileExt(AFilenameUTF8);
  if ext <> '' then
  begin
    for i := 0 to high(PaletteFormats) do
      if CompareText(PaletteFormats[i].ext,ext) = 0 then
      begin
        result := PaletteFormats[i].formatIndex;
        exit;
      end;
  end;
  result := palUnknown;
end;

end.

