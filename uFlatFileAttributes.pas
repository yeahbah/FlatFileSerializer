unit uFlatFileAttributes;

interface

type
  TSpaceFill = (sfZero, sfSpace);

  TFlatFileItemAttribute = class(TCustomAttribute)
  private
    fOrder: integer;
    fSize: integer;
    fSpaceFill: TSpaceFill;
    fAlignRight: boolean;
    fRecordIdentifier: string;
    function GetSpaceFillChar: char;
  public
    constructor Create(const aOrder, aSize: integer); overload;
    constructor Create(const aOrder, aSize: integer; const aRecordIdentifier: string); overload;
    constructor Create(const aOrder: integer; const aSize: integer;
      const aSpaceFill: TSpaceFill; const aAlignRight: boolean = false); overload;
    property RecordIdentifier: string read fRecordIdentifier write fRecordIdentifier;
    property Order: integer read fOrder write fOrder;
    property Size: integer read fSize write fSize;
    property SpaceFill: TSpaceFill read fSpaceFill write fSpaceFill;
    property SpaceFillChar: char read GetSpaceFillChar;
    property AlignRight: boolean read fAlignRight write fAlignRight;
  end;

  TFlatFileRecordAttribute = class(TCustomAttribute)
  private
    fOrder: integer;
  public
    property Order: integer read fOrder write fOrder;
    constructor Create(aOrder: integer);
  end;

  TFlatFileRecordListAttribute = class(TFlatFileRecordAttribute)

  end;

implementation

uses
  SysUtils;

{ TFlatFileItemAttribute }

constructor TFlatFileItemAttribute.Create(const aOrder, aSize: integer);
begin
  fOrder := aOrder;
  fSize := aSize;
  fSpaceFill := TSpaceFill.sfSpace;
  fAlignRight := false;
  fRecordIdentifier := string.Empty;
end;

constructor TFlatFileItemAttribute.Create(const aOrder, aSize: integer; const aSpaceFill: TSpaceFill;
  const aAlignRight: boolean);
begin
  Create(aOrder, aSize, '');
  fSpaceFill := aSpaceFill;
  fAlignRight := aAlignRight;
end;

constructor TFlatFileItemAttribute.Create(const aOrder,
  aSize: integer; const aRecordIdentifier: string);
begin
  Create(aOrder, aSize);
  fRecordIdentifier := aRecordIdentifier;
end;

function TFlatFileItemAttribute.GetSpaceFillChar: char;
begin
  if fSpaceFill = TSpaceFill.sfZero then
    exit('0');

  exit(' ');
end;

{ TFlatFileRecordAttribute }

constructor TFlatFileRecordAttribute.Create(aOrder: integer);
begin
  fOrder := aOrder;
end;

end.


