unit uFlatFileAttributes;

interface

type
  TFlatFileItemAttribute = class(TCustomAttribute)
  private
    fPosition: integer;
    fSize: integer;
    fFillChar: char;
  public
    constructor Create(aPosition: integer; aSize: integer; aFillChar: char); overload;
    constructor Create(aPosition, aSize: integer); overload;
    property Position: integer read fPosition write fPosition;
    property Size: integer read fSize write fSize;
    property FillChar: char read fFillChar write fFillChar;
  end;

implementation

{ TFlatFileItemAttribute }

constructor TFlatFileItemAttribute.Create(aPosition, aSize: integer);
begin
  fPosition := aPosition;
  fSize := aSize;
  fFillChar := ' ';
end;

constructor TFlatFileItemAttribute.Create(aPosition, aSize: integer; aFillChar: char);
begin
  Create(aPosition, aSize);
  fFillChar := aFillChar;
end;

end.


