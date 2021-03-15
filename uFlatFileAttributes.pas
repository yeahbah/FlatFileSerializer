unit uFlatFileAttributes;

interface

type

  TFlatFileItemAttribute = class(TCustomAttribute)
  private
    fPosition: integer;
    fSize: integer;
    fFillChar: char;
    fAlignRight: boolean;
  public
    constructor Create(aPosition, aSize: integer); overload;
    constructor Create(aPosition: integer; aSize: integer; aFillChar: char; aAlignRight: boolean = false); overload;
    property Position: integer read fPosition write fPosition;
    property Size: integer read fSize write fSize;
    property FillChar: char read fFillChar write fFillChar;
    property AlignRight: boolean read fAlignRight write fAlignRight;
  end;

implementation

{ TFlatFileItemAttribute }

constructor TFlatFileItemAttribute.Create(aPosition, aSize: integer);
begin
  fPosition := aPosition;
  fSize := aSize;
  fFillChar := ' ';
  fAlignRight := false;
end;

constructor TFlatFileItemAttribute.Create(aPosition, aSize: integer; aFillChar: char;
  aAlignRight: boolean);
begin
  Create(aPosition, aSize);
  fFillChar := aFillChar;
  fAlignRight := aAlignRight;
end;

end.


