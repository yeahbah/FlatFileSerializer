unit uFlatFileModel;

interface

uses
  Rtti, Spring.Collections, uFlatFileAttributes, Generics.Collections;

type
  TFlatFileModelPropertyRecord = record
    Value: TValue;
    FlatFileItemAttribute: TFlatFileItemAttribute;
    constructor Create(aValue: TValue; aFlatFileItemAttribute: TFlatFileItemAttribute);
  end;

  TFlatFileModelBase = class abstract
  strict private
    function GetProperties: TArray<TFlatFileModelPropertyRecord>;
  private
    function GetTotalSize: integer;
  public
    function ToString: string; override;
    procedure SetFromString(aValue: string); virtual;
    property TotalSize: integer read GetTotalSize;
  end;

implementation

uses
  System.Generics.Defaults, SysUtils;


{ TFlatFileModelBase }

function TFlatFileModelBase.GetProperties: TArray<TFlatFileModelPropertyRecord>;
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
      .Create(prop.GetValue(self), flatFileItemAttribute));

    attrList.Clear;
  end;

  Result := propertyList.ToArray;
end;

function TFlatFileModelBase.GetTotalSize: integer;
begin

end;

procedure TFlatFileModelBase.SetFromString(aValue: string);
begin

end;

function TFlatFileModelBase.ToString: string;
var
  propertyList: TArray<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
  s: TStringBuilder;
  propValue: string;
begin
  propertyList := GetProperties;
  TArray.Sort<TFlatFileModelPropertyRecord>(propertyList,
    TDelegatedComparer<TFlatFileModelPropertyRecord>.Create(
      function (const left, right: TFlatFileModelPropertyRecord): integer
      begin
        result := left.FlatFileItemAttribute.Position - right.FlatFileItemAttribute.Position;
      end));

  s := TStringBuilder.Create;
  try
    for prop in propertyList do
    begin
      case prop.Value.Kind of
        tkFloat:
          begin
            if prop.Value.TypeInfo = System.TypeInfo(TDate) then
              propValue := FormatDateTime('yyyyMMdd', prop.Value.AsType<TDate>())
            else if prop.Value.TypeInfo = System.TypeInfo(TDateTime) then
              propValue := FormatDateTime('yyyyMMddHHmmss', prop.Value.AsType<TDateTime>())
            else
            begin
              propValue := FormatFloat('#.00', prop.Value.AsExtended);
              propValue := propValue.Replace('.', '');
            end;
          end
        else
          propValue := prop.Value.ToString().Trim();
      end;

      if prop.FlatFileItemAttribute.AlignRight then
        propValue := propValue.PadLeft(prop.FlatFileItemAttribute.Size, prop.FlatFileItemAttribute.FillChar)
      else
        propValue := propValue.PadRight(prop.FlatFileItemAttribute.Size, prop.FlatFileItemAttribute.FillChar);

      s.Append(propValue);
    end;
    result := s.ToString;
  finally
    s.Free;
  end;
end;

{ TFlatFileModelProperty }

constructor TFlatFileModelPropertyRecord.Create(aValue: TValue;
  aFlatFileItemAttribute: TFlatFileItemAttribute);
begin
  Value := aValue;
  FlatFileItemAttribute := aFlatFileItemAttribute;
end;

end.
