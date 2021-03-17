unit uFlatFileModel;

interface

uses
  Rtti, Spring.Collections, Generics.Collections;

type
  TFlatFileModelBase = class abstract
  strict private
    function GetTotalSize: integer;
  public
    function ToString: string; override;
    procedure SetFromString(aValue: string); virtual;
    property TotalSize: integer read GetTotalSize;
  end;

  TFlatFileModelBaseClass = class of TFlatFileModelBase;

implementation

uses
  System.Generics.Defaults, SysUtils, DateUtils, uFlatFileExceptions, uFlatFileModelPropertyRecord;

var
  modelPropertyListCache: TDictionary<TFlatFileModelBase, IList<TFlatFileModelPropertyRecord>>;

{ TFlatFileModelBase }

function TFlatFileModelBase.GetTotalSize: integer;
var
  properties: IList<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
begin
  result := 0;
  properties := TFlatFileModelPropertyRecord.GetModelPropertyList(self);
  for prop in properties do
  begin
    result := result + prop.FlatFileItemAttribute.Size;
  end;
end;

procedure TFlatFileModelBase.SetFromString(aValue: string);
var
  properties: IList<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
  value, identifier: string;
  currentIndex, temp: integer;
  year, month, day, hour, min, sec: word;
begin
  if aValue.Length <> TotalSize then
    raise ERecordSizeMismatch.CreateFmt('Record mismatch. Expected size of %s record string is %d', [self.ClassName, TotalSize]);

  properties := TFlatFileModelPropertyRecord.GetModelPropertyList(self);

  // normally the identifier is somewhere in the beginning of the text
  // so this should be a quick query otherwise whoever designed the flat file should be crucified.
  currentIndex := 0;
  for prop in properties do
  begin
    if prop.FlatFileItemAttribute.RecordIdentifier <> string.Empty then
    begin
      identifier := aValue
        .Substring(currentIndex, prop.FlatFileItemAttribute.Size)
        .Trim();

      // aValue is not the right text to read
      // this is case sensitive matching
      if string.Compare(identifier, prop.FlatFileItemAttribute.RecordIdentifier) <> 0 then
        exit;

      break;
    end;
    currentIndex := currentIndex + prop.FlatFileItemAttribute.Size;
  end;

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
          if prop.Value.TypeInfo = System.TypeInfo(TDateTime) then
          begin
            year := StrToInt(value.Substring(0, 4));
            month := StrToInt(value.Substring(4, 2));
            day := StrToInt(value.Substring(6, 2));
            hour := StrToInt(value.Substring(8, 2));
            min := StrToInt(value.Substring(10, 2));
            sec := StrToInt(value.Substring(12, 2));
            prop.ObjectProperty.SetValue(prop.ObjectInstance, EncodeDateTime(year, month, day, hour, min, sec, 0));
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
  propertyList: IList<TFlatFileModelPropertyRecord>;
  prop: TFlatFileModelPropertyRecord;
  s: TStringBuilder;
  propValue: string;
begin
  propertyList := TFlatFileModelPropertyRecord.GetModelPropertyList(self);

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



end.
