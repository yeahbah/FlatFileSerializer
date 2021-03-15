unit uFlatFileModel;

interface

uses
  Rtti, Spring.Collections, uFlatFileAttributes, Generics.Collections;

type
  TFlatFileModelPropertyRecord = record
  private
    function GetValue: TValue;
  public
    ObjectInstance: Pointer;
    ObjectProperty: TRttiProperty;
    FlatFileItemAttribute: TFlatFileItemAttribute;
    constructor Create(aObjectInstance: Pointer;
      aObjectProperty: TRttiProperty; aFlatFileItemAttribute: TFlatFileItemAttribute);
    property Value: TValue read GetValue;
  end;

  TFlatFileModelBase = class abstract
  strict private
    function GetProperties: TArray<TFlatFileModelPropertyRecord>;
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
      .Create(self, prop, flatFileItemAttribute));

    attrList.Clear;
  end;

  // return the list of properties sorted by position
  result := propertyList.ToArray;
  TArray.Sort<TFlatFileModelPropertyRecord>(result,
    TDelegatedComparer<TFlatFileModelPropertyRecord>.Create(
      function (const left, right: TFlatFileModelPropertyRecord): integer
      begin
        result := left.FlatFileItemAttribute.Order - right.FlatFileItemAttribute.Order;
      end));

end;

function TFlatFileModelBase.GetTotalSize: integer;
var
  properties: TArray<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
begin
  result := 0;
  properties := GetProperties();
  for prop in properties do
  begin
    result := result + prop.FlatFileItemAttribute.Size;
  end;
end;

procedure TFlatFileModelBase.SetFromString(aValue: string);
var
  properties: TArray<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
  value: string;
  currentIndex, temp: integer;
  year, month, day: word;
begin
  properties := GetProperties();

  currentIndex := 0;
  for prop in properties do
  begin
    value := aValue
      .Substring(currentIndex, prop.FlatFileItemAttribute.Size)
      .Trim();

    case prop.Value.Kind of
      tkFloat:
        begin
          if prop.Value.TypeInfo = System.TypeInfo(TDate) then
          begin
            year := StrToInt(value.Substring(0, 4));
            month := StrToInt(value.Substring(4, 2));
            day := StrToInt(value.Substring(6, 2));
            prop.ObjectProperty.SetValue(prop.ObjectInstance, EncodeDate(year, month, day));
          end
          else
          begin
            value := value.Insert(prop.FlatFileItemAttribute.Size -2, '.');
            prop.ObjectProperty.SetValue(prop.ObjectInstance, StrToFloat(value));
          end;
        end;

      tkInteger:
        begin
          temp := integer.Parse(value);
          prop.ObjectProperty.SetValue(prop.ObjectInstance, temp);
        end;

      tkString, tkUString:
        prop.ObjectProperty.SetValue(prop.ObjectInstance, value);

    end;
    currentIndex := currentIndex + prop.FlatFileItemAttribute.Size;
  end;
end;

function TFlatFileModelBase.ToString: string;
var
  propertyList: TArray<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
  s: TStringBuilder;
  propValue: string;
begin
  propertyList := GetProperties;

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
        propValue := propValue.PadLeft(prop.FlatFileItemAttribute.Size, prop.FlatFileItemAttribute.SpaceFillChar)
      else
        propValue := propValue.PadRight(prop.FlatFileItemAttribute.Size, prop.FlatFileItemAttribute.SpaceFillChar);

      s.Append(propValue);
    end;
    result := s.ToString;
  finally
    s.Free;
  end;
end;

{ TFlatFileModelProperty }

constructor TFlatFileModelPropertyRecord.Create(aObjectInstance: Pointer;
  aObjectProperty: TRttiProperty; aFlatFileItemAttribute: TFlatFileItemAttribute);
begin
  ObjectInstance := aObjectInstance;
  ObjectProperty := aObjectProperty;
  FlatFileItemAttribute := aFlatFileItemAttribute;
end;

function TFlatFileModelPropertyRecord.GetValue: TValue;
begin
  result := ObjectProperty.GetValue(ObjectInstance);
end;

end.
