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
    function ProcessDocumentLine(aLine: string; aPropertyMap: TPropertyMap): boolean; overload;
    function ProcessDocumentLine(aLine: string; aPropertyMap: TPropertyMap; aFlatFileDocument: T): boolean; overload;
  public
    procedure Serialize(aOutputStream: TStringStream; aFlatFileDocument: T);
    procedure Deserialize(aInputStream: TStringStream; out aFlatFileDocument: T);
    class function GetSubTypeItemFromList(aQualifiedListName: string): string;
  end;

implementation

uses
  RegularExpressions;

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
  out aFlatFileDocument: T);
var
  lines: TStringList;
  line: string;
  properties: IList<TPropertyMap>;
  prop: TPropertyMap;
  value: string;
  processed: boolean;

begin
  properties := GetPropertyMap(aFlatFileDocument);
  lines := TStringList.Create;
  try
    aInputStream.Position := 0;
    lines.LoadFromStream(aInputStream);

    // O(N * M * L ) or maybe O(N^3), so much loops
    for line in lines do
    begin
      processed := false;
      for prop in properties do
      begin

        // a list item
        if prop.RecordAttribute is TFlatFileRecordListAttribute then
        begin
          processed := ProcessDocumentLine(line, prop, aFlatFileDocument);
        end
        else
        begin
          processed := ProcessDocumentLine(line, prop);
        end;

        if processed then
          break;
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
  s: string;
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
        s := prop.PropertyType.QualifiedName;
        // expand the list
        obj := prop.GetValue(Pointer(aFlatFileDocument)).AsPointer;
        if obj = nil then
        begin
          // create the list
          objectType.GetMethod('CreateLists').Invoke(aFlatFileDocument, []);
          obj := prop.GetValue(Pointer(aFlatFileDocument)).AsPointer;
          attrList.Add(TPropertyMap.Create(nil, TFlatFileRecordListAttribute(attr), prop, nil));
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
  aQualifiedListName: string): string;
var
  regEx: TRegEx;
  matchCollections: TMatchCollection;
begin
  regEx := TRegEx.Create('.+\.(.+\<(.+)\>)');
  matchCollections := regEx.Matches(aQualifiedListName);
  if matchCollections.Count = 0 then
    raise Exception.Create('Unable to determine list type');

  result := matchCollections[0].Groups[2].Value;

end;

function TFlatFileSerializer<T>.ProcessDocumentLine(aLine: string;
  aPropertyMap: TPropertyMap; aFlatFileDocument: T): boolean;
var
  propType: TRttiType;
  ctx: TRttiContext;
  listItemPointer: Pointer;
  props: IList<TFlatFileModelPropertyRecord>;
  currentIndex: integer;
  modelProperty: TFlatFileModelPropertyRecord;
  identifier: string;
  listObject: IList<TFlatFileModelBase>;
  itemIndex: integer;
begin
  result := false;
  ctx := TRttiContext.Create;
  propType := ctx.FindType(GetSubTypeItemFromList(aPropertyMap.RecordProperty.PropertyType.QualifiedName));
  listItemPointer := propType.GetMethod('Create').Invoke(propType.AsInstance.MetaClassType, []).AsPointer;
  try
    props := TFlatFileModelPropertyRecord.GetModelPropertyList(listItemPointer);
  finally
    TFlatFileModelBase(listItemPointer).Free;
  end;

  currentIndex := 0;
  for modelProperty in props do
  begin
    if modelProperty.FlatFileItemAttribute.RecordIdentifier <> string.Empty then
    begin
      // problem here is that it can read any random value in the line and can
      // match the identifier. I blame the guy who designed the flat file structure if this fail.
      identifier := aLine
        .Substring(currentIndex, modelProperty.FlatFileItemAttribute.Size)
        .Trim();

      // this is case sensitive matching
      if string.Compare(identifier, modelProperty.FlatFileItemAttribute.RecordIdentifier) = 0 then
      begin
        // create the necessary object
        // read the line into that object
        // move on to the next line
        listObject := IList<TFlatFileModelBase>(aPropertyMap.RecordProperty.GetValue(Pointer(aFlatFileDocument)).AsPointer);

        propType := ctx.FindType(GetSubTypeItemFromList(aPropertyMap.RecordProperty.PropertyType.QualifiedName));
        listItemPointer := propType.GetMethod('Create').Invoke(propType.AsInstance.MetaClassType, []).AsPointer;

        itemIndex := listObject.Add(listItemPointer);
        listObject[itemIndex].SetFromString(aLine);
        Exit(true);
      end;
    end;
    currentIndex := currentIndex + modelProperty.FlatFileItemAttribute.Size;
  end;
end;

function TFlatFileSerializer<T>.ProcessDocumentLine(aLine: string;
  aPropertyMap: TPropertyMap): boolean;
var
  currentIndex: integer;
  modelProperty: TFlatFileModelPropertyRecord;
  identifier: string;
begin
  result := false;
  currentIndex := 0;
  for modelProperty in aPropertyMap.ModelProperties do
  begin
    if modelProperty.FlatFileItemAttribute.RecordIdentifier <> string.Empty then
    begin
      // problem here is that it can read any random value in the line and can
      // match the identifier. I blame the guy who designed the flat file structure if this fail.
      identifier := aLine
        .Substring(currentIndex, modelProperty.FlatFileItemAttribute.Size)
        .Trim();

      // this is case sensitive matching
      if string.Compare(identifier, modelProperty.FlatFileItemAttribute.RecordIdentifier) = 0 then
      begin
        // create the necessary object
        // read the line into that object
        // move on to the next line
        aPropertyMap.ModelInstance.SetFromString(aLine);
        Exit(true);
      end;
    end;
    currentIndex := currentIndex + modelProperty.FlatFileItemAttribute.Size;
  end;
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
