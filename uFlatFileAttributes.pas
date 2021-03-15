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

end.


