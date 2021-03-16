unit uFlatFileAttributes;

interface

type
  TSpaceFill = (sfZero, sfSpace);

  ///  Required attribute for all flat file models.
  ///  Flat file models must have property as an identifier
  ///  Use this attribute to define it
  TFlatFileRecordIdentifier = class(TCustomAttribute)
  private
    fIdentifier: string;
  public
    constructor Create(aIdentifier: string);
    property Identifier: string read fIdentifier write fIdentifier;
  end;

  TFlatFileItemAttribute = class(TCustomAttribute)
  private
    fOrder: integer;
    fSize: integer;
    fSpaceFill: TSpaceFill;
    fAlignRight: boolean;
    function GetSpaceFillChar: char;
  public
    constructor Create(aPosition, aSize: integer); overload;
    constructor Create(aPosition: integer; aSize: integer; aSpaceFill: TSpaceFill; aAlignRight: boolean = false); overload;
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

{ TFlatFileItemAttribute }

constructor TFlatFileItemAttribute.Create(aPosition, aSize: integer);
begin
  fOrder := aPosition;
  fSize := aSize;
  fSpaceFill := TSpaceFill.sfSpace;
  fAlignRight := false;
end;

constructor TFlatFileItemAttribute.Create(aPosition, aSize: integer; aSpaceFill: TSpaceFill;
  aAlignRight: boolean);
begin
  Create(aPosition, aSize);
  fSpaceFill := aSpaceFill;
  fAlignRight := aAlignRight;
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

{ TFlatFileRecordIdentifier }

constructor TFlatFileRecordIdentifier.Create(aIdentifier: string);
begin
  fIdentifier := aIdentifier;
end;

end.


