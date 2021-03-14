unit uFlatFileModel;

interface

uses
  Rtti, Spring.Collections, uFlatFileAttributes;

type
  TFlatFileModelPropertyRecord = record
    Position: integer;
    Size: integer;
    FillChar: char;
    Value: TValue;
    constructor Create(aPosition: integer; aSize: integer; aFillChar: char; aValue: TValue);
  end;

  TFlatFileModel = class abstract
  strict private
    function GetProperties: IList<TFlatFileModelPropertyRecord>;
  public
    function ToString: string; override;
  end;

implementation

uses
  System.Generics.Defaults, SysUtils;


{ TFlatFileModel }

function TFlatFileModel.GetProperties: IList<TFlatFileModelPropertyRecord>;
var
  ctx: TRttiContext;
  t: TRttiType;
  prop: TRttiProperty;
  flatFileItemAttribute: TFlatFileItemAttribute;
  attrList: IList<TCustomAttribute>;
  propertyList: IList<TFlatFileModelPropertyRecord>;
begin
  ctx := TRttiContext.Create;
  t := ctx.GetType(self.ClassInfo);
  attrList := TCollections.CreateList<TCustomAttribute>;
  propertyList := TCollections.CreateList<TFlatFileModelPropertyRecord>;

  for prop in t.GetProperties do
  begin
    attrList.AddRange(prop.GetAttributes());
    flatFileItemAttribute := attrList.SingleOrDefault(
      function (const x: TCustomAttribute): boolean
      begin
        Result := x is TFlatFileItemAttribute;
      end, nil) as TFlatFileItemAttribute;

    if flatFileItemAttribute = nil then
      continue;

    propertyList.Add(TFlatFileModelPropertyRecord
      .Create(flatFileItemAttribute.Position,
              flatFileItemAttribute.Size,
              flatFileItemAttribute.FillChar,
              prop.GetValue(self)));

  end;

  Result := propertyList;
end;

function TFlatFileModel.ToString: string;
var
  propertyList: IList<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
  s: TStringBuilder;
begin
  propertyList := GetProperties;
  propertyList.Sort(
    TDelegatedComparer<TFlatFileModelPropertyRecord>.Create(
      function (const left, right: TFlatFileModelPropertyRecord): integer
      begin
        result := left.Position - right.Position;
      end));

  s := TStringBuilder.Create;
  try
    for prop in propertyList do
    begin
      // TODO: type convertion
      s.Append(prop.Value.ToString);
    end;
    result := s.ToString;
  finally
    s.Free;
  end;
end;

{ TFlatFileModelProperty }

constructor TFlatFileModelPropertyRecord.Create(aPosition, aSize: integer;
  aFillChar: char; aValue: TValue);
begin
  Position := aPosition;
  Size := aSize;
  FillChar := aFillChar;
  Value := aValue;
end;

end.
