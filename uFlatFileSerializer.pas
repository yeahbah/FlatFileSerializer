unit uFlatFileSerializer;

interface

uses
  uFlatFileDocument, uFlatFileModel, Classes, Spring.Collections, Generics.Collections,
  Rtti, uFlatFileAttributes, Generics.Defaults, SysUtils, uFlatFileExceptions, Spring,
  uFlatFileModelPropertyRecord;

type
  TPropertyMap = record
  private
    fRecordAttribute: TFlatFileRecordAttribute;
    fModelInstance: TFlatFileModelBase;
    fModelProperties: IList<TFlatFileModelPropertyRecord>;
  public
    RecordProperty: TRttiProperty;
    constructor Create(aModelInstance: TFlatFileModelBase;
      aRecordAttribute: TFlatFileRecordAttribute; aRecordProperty: TRttiProperty;
      aModelProperties: IList<TFlatFileModelPropertyRecord>);
    property ModelInstance: TFlatFileModelBase read fModelInstance write fModelInstance;
    property RecordAttribute: TFlatFileRecordAttribute read fRecordAttribute;
    property ModelProperties: IList<TFlatFileModelPropertyRecord> read fModelProperties write fModelProperties;
  end;

  TFlatFileSerializer<T: TFlatFileDocumentBase> = class
  private
    function GetPropertyMap(aFlatFileDocument: T): IList<TPropertyMap>;
  public
    procedure Serialize(aOutputStream: TStringStream; aFlatFileDocument: T);
    procedure Deserialize(aInputStream: TStringStream; out aResult: T);
    class function GetSubTypeItemFromList(aList: IList): TClass;
  end;

implementation

{ TPropertyMap }

constructor TPropertyMap.Create(aModelInstance: TFlatFileModelBase;
  aRecordAttribute: TFlatFileRecordAttribute; aRecordProperty: TRttiProperty;
  aModelProperties: IList<TFlatFileModelPropertyRecord>);
begin
  fModelInstance := aModelInstance;
  fRecordAttribute := aRecordAttribute;
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
  listItem: TValue;
  listItemPointer: Pointer;
  props: IList<TFlatFileModelPropertyRecord>;
  m: TRttiMethod;
  obj: IList<TFlatFileModelBase>;
  itemIndex: integer;
begin
  properties := GetPropertyMap(aResult);
  lines := TStringList.Create;
  try
    aInputStream.Position := 0;
    lines.LoadFromStream(aInputStream);
    ctx := TRttiContext.Create;

    // O(N + M)
    for line in lines do
    begin
      processed := false;
      for prop in properties do
      begin
        if processed then
          break;

        // a list item
        if prop.RecordAttribute is TFlatFileRecordListAttribute then
        begin
          propType := ctx.GetType(prop.ModelInstance.ClassInfo);
          listItemPointer := propType.GetMethod('Create').Invoke(propType.AsInstance.MetaClassType, []).AsPointer;

          props := TFlatFileModelPropertyRecord.GetModelPropertyList(listItemPointer);

          currentIndex := 0;
          for modelProperty in props do
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
                obj := IList<TFlatFileModelBase>(prop.RecordProperty.GetValue(Pointer(aResult)).AsPointer);
                itemIndex := obj.Add(listItemPointer);
                obj[itemIndex].SetFromString(line);
                processed := true;
                break;
              end;
            end;
            currentIndex := currentIndex + modelProperty.FlatFileItemAttribute.Size;
          end;

        end
        else
        begin

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
      if not (attr is TFlatFileRecordAttribute) then
        continue;

      if prop.PropertyType.QualifiedName.Contains('IList') then
      begin
        // expand the list
        obj := prop.GetValue(Pointer(aFlatFileDocument)).AsPointer;
        if obj = nil then
        begin
          // create the list
          objectType.GetMethod('CreateLists').Invoke(aFlatFileDocument, []);
          obj := prop.GetValue(Pointer(aFlatFileDocument)).AsPointer;
          attrList.Add(TPropertyMap.Create(IList<TFlatFileModelBase>(obj)[0], TFlatFileRecordListAttribute(attr), prop, nil));
          IList<TFlatFileModelBase>(obj).Delete(0);
        end;

        recordList := IList<TFlatFileModelBase>(obj);
        for recordItem in recordList do
        begin
          attrList.Add(TPropertyMap.Create(recordItem, TFlatFileRecordListAttribute(attr), prop, nil))
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

  attrList.Sort(TDelegatedComparer<TPropertyMap>.Create(
      function (const left, right: TPropertyMap): integer
      begin
        result := left.RecordAttribute.Order - right.RecordAttribute.Order;
      end));
  result := attrList;

end;

class function TFlatFileSerializer<T>.GetSubTypeItemFromList(
  aList: IList): TClass;
var
  ctxRtti  : TRttiContext;
  typeRtti : TRttiType;
  atrbRtti : TCustomAttribute;
  methodRtti: TRttiMethod;
  parameterRtti: TRttiParameter;
begin
  result := nil;

  ctxRtti  := TRttiContext.Create;
  typeRtti := ctxRtti.GetType( TObject(aList).ClassInfo );
  methodRtti := typeRtti.GetMethod('Add');
  for parameterRtti in methodRtti.GetParameters do
  begin
    if SameText(parameterRtti.Name,'Value') then
    begin
      if parameterRtti.ParamType.IsInstance then
        result := parameterRtti.ParamType.AsInstance.MetaclassType;
      break;
    end;
  end;
  ctxRtti.Free;

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
