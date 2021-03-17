unit uFlatFileSerializer;

interface

uses
  uFlatFileDocument, uFlatFileModel, Classes, Spring.Collections, Generics.Collections,
  Rtti, uFlatFileAttributes, Generics.Defaults, SysUtils, uFlatFileExceptions, Spring;


type
  TPropertyMap = record
  public
    ModelInstance: TFlatFileModelBase;
    RecordAttribute: TFlatFileRecordAttribute;
    RecordProperty: TRttiProperty;
    ModelProperties: IList<TFlatFileModelPropertyRecord>;
    constructor Create(aModelInstance: TFlatFileModelBase;
      aRecordAttribute: TFlatFileRecordAttribute; aRecordProperty: TRttiProperty;
      aModelProperties: IList<TFlatFileModelPropertyRecord>);
  end;

  TFlatFileSerializer<T: TFlatFileDocumentBase> = class
  private
    function GetPropertyMap(aFlatFileDocument: T): IList<TPropertyMap>;
  public
    procedure Serialize(aOutputStream: TStringStream; aFlatFileDocument: T);
    procedure Deserialize(aInputStream: TStringStream; out aResult: T);
  end;

implementation

{ TPropertyMap }

constructor TPropertyMap.Create(aModelInstance: TFlatFileModelBase;
  aRecordAttribute: TFlatFileRecordAttribute; aRecordProperty: TRttiProperty;
  aModelProperties: IList<TFlatFileModelPropertyRecord>);
begin
  ModelInstance := aModelInstance;
  RecordAttribute := aRecordAttribute;
  RecordProperty := aRecordProperty;
  ModelProperties := aModelProperties;
end;

{ TFlatFileSerizalier<T> }

procedure TFlatFileSerializer<T>.Deserialize(aInputStream: TStringStream;
  out aResult: T);
var
  lines: TStringList;
  line: string;
  properties: IList<TPropertyMap>;
  prop: TPropertyMap;
  value: string;
  ctx: TRttiContext;
  propType: TRttiType;
  p: TRttiProperty;
  attr: TCustomAttribute;
  currentIndex: integer;
  modelProperty: TFlatFileModelPropertyRecord;
  identifier: string;
  processed: boolean;
begin
  properties := GetPropertyMap(aResult);
  lines := TStringList.Create;
  try
    aInputStream.Position := 0;
    lines.LoadFromStream(aInputStream);

    // O(N + M)
    for line in lines do
    begin
      processed := false;
      for prop in properties do
      begin
        if processed then
          break;

        currentIndex := 0;
        for modelProperty in prop.ModelProperties do
        begin
          if modelProperty.FlatFileItemAttribute.RecordIdentifier <> string.Empty then
          begin
            // problem here is that it can read any random value in the line and can
            // match the identifier. I blame the guy who designed the flat file structure if this fail.
            identifier := line
              .Substring(currentIndex, modelProperty.FlatFileItemAttribute.Size)
              .Trim();

            // this is case sensitive matching
            if string.Compare(identifier, modelProperty.FlatFileItemAttribute.RecordIdentifier) = 0 then
            begin
              // create the necessary object
              // read the line into that object
              // move on to the next line
              prop.ModelInstance.SetFromString(line);
              processed := true;
              break;
            end;
          end;
          currentIndex := currentIndex + modelProperty.FlatFileItemAttribute.Size;
        end;

      end;

    end;
  finally
    lines.Free;
  end;

end;

function TFlatFileSerializer<T>.GetPropertyMap(
  aFlatFileDocument: T): IList<TPropertyMap>;
var
  ctx: TRttiContext;
  objectType: TRttiType;
  prop: TRttiProperty;
  attrList: IList<TPropertyMap>;
  attr: TCustomAttribute;
  value: TFlatFileModelBase;
  recordList: IList<TFlatFileModelBase>;
  recordItem: TFlatFileModelBase;
  obj: Pointer;
  flatFileModelList: IList<TFlatFileModelPropertyRecord>;
  x: TRttiType;
begin
  ctx := TRttiContext.Create;
  objectType := ctx.GetType(T);
  attrList := TCollections.CreateList<TPropertyMap>();

  for prop in objectType.GetProperties() do
  begin
    for attr in prop.GetAttributes() do
    begin
      if attr is TFlatFileRecordAttribute then
      begin
        if prop.PropertyType.QualifiedName.Contains('IList') then
        begin
          // expand the list
          obj := prop.GetValue(Pointer(aFlatFileDocument)).AsPointer;
          if obj = nil then
          begin
            // need the class type of the list item
//            obj := TCollections.CreateList<prop.PropertyType.AsInstance.MetaclassType.Cl
            break;
          end;

          recordList := IList<TFlatFileModelBase>(obj);
          for recordItem in recordList do
          begin
            attrList.Add(TPropertyMap.Create(recordItem, TFlatFileRecordAttribute(attr), prop, nil))
          end;
        end
        else
        begin
          value := prop.GetValue(Pointer(aFlatFileDocument)).AsType<TFlatFileModelBase>();
          // read all the properties
          if value = nil then
          begin
            // create instance
            x := ctx.GetType(prop.PropertyType.AsInstance.MetaclassType.ClassInfo);
            value := x.GetMethod('Create').Invoke(x.AsInstance.MetaClassType, []).AsPointer;
            prop.SetValue(Pointer(aFlatFileDocument), value);
          end;
          flatFileModelList := TFlatFileModelPropertyRecord.GetModelPropertyList(value);
          attrList.Add(TPropertyMap.Create(value, TFlatFileRecordAttribute(attr), prop, flatFileModelList));
        end;
      end;

    end;
  end;

  attrList.Sort(TDelegatedComparer<TPropertyMap>.Create(
      function (const left, right: TPropertyMap): integer
      begin
        result := left.RecordAttribute.Order - right.RecordAttribute.Order;
      end));
  result := attrList;

end;

procedure TFlatFileSerializer<T>.Serialize(aOutputStream: TStringStream;
  aFlatFileDocument: T);
var
  properties: IList<TPropertyMap>;
  prop: TPropertyMap;
  flatFileModel: TFlatFileModelBase;
  value: string;
begin
  aOutputStream.Position := 0;
  properties := GetPropertyMap(aFlatFileDocument);
  for prop in properties do
  begin
    // must be child of TFlatFileModelBase
    if not (prop.ModelInstance is TFlatFileModelBase) then
      raise EInvalidRecordParentClass.CreateFmt('%s must be a descendant of TFlatFileModelBase', [prop.RecordProperty.ClassName]);

      value := prop.ModelInstance.ToString() + chr(13) + chr(10);
      aOutputStream.WriteString(value);

  end;

end;

end.
