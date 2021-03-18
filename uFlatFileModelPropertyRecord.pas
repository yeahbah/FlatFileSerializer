unit uFlatFileModelPropertyRecord;

interface

uses
  Rtti, uFlatFileModel, uFlatFileAttributes, Spring.Collections;

type
  TFlatFileModelPropertyRecord = class
  private
    function GetValue: TValue;
  public
    ObjectInstance: Pointer;
    ObjectProperty: TRttiProperty;
    FlatFileItemAttribute: TFlatFileItemAttribute;
    constructor Create(aObjectInstance: Pointer;
      aObjectProperty: TRttiProperty; aFlatFileItemAttribute: TFlatFileItemAttribute);
    property Value: TValue read GetValue;
    class function GetModelPropertyList(const aFlatFileModel: TFlatFileModelBase): IList<TFlatFileModelPropertyRecord>;
  end;

implementation

uses
  uFlatFileExceptions, SysUtils, Generics.Defaults, Generics.Collections;

{ TFlatFileModelProperty }

class function TFlatFileModelPropertyRecord.GetModelPropertyList(
  const aFlatFileModel: TFlatFileModelBase): IList<TFlatFileModelPropertyRecord>;
var
  ctx: TRttiContext;
  t: TRttiType;
  prop: TRttiProperty;
  attrList: IList<TCustomAttribute>;
  propertyList: IList<TFlatFileModelPropertyRecord>;
  attr: TCustomAttribute;
  identifierCount: integer;
begin
  ctx := TRttiContext.Create;
  t := ctx.GetType(aFlatFileModel.ClassInfo);
  attrList := TCollections.CreateList<TCustomAttribute>;
  propertyList := TCollections.CreateList<TFlatFileModelPropertyRecord>;

  for prop in t.GetProperties do
  begin
    for attr in prop.GetAttributes() do
    begin
      if attr is TFlatFileItemAttribute then
      begin
        propertyList.Add(TFlatFileModelPropertyRecord.Create(aFlatFileModel, prop, TFlatFileItemAttribute(attr)));
      end;
    end;
  end;

  // model must have one Identifier property
  identifierCount := propertyList.Where(
    function (const x: TFlatFileModelPropertyRecord): boolean
    begin
      result := x.FlatFileItemAttribute.RecordIdentifier.Trim() <> string.Empty;
    end).Count;

  if identifierCount = 0  then
    raise EUndefinedRecordIdentifier.CreateFmt(
      'No record identifier defined for class %s. Model must have one record identifier property', [aFlatFileModel.ClassName]);

  if identifierCount > 1 then
    raise EMultipleRecordIdentifier.CreateFmt(
      'There are multiple record identifiers for class %s. There should only be one.', [aFlatFileModel.ClassName]);

  // return the list of properties sorted by position
  propertyList.Sort(
    TDelegatedComparer<TFlatFileModelPropertyRecord>.Create(
      function (const left, right: TFlatFileModelPropertyRecord): integer
      begin
        result := left.FlatFileItemAttribute.Order - right.FlatFileItemAttribute.Order;
      end));

  result := propertyList;

end;

constructor TFlatFileModelPropertyRecord.Create(aObjectInstance: Pointer;
  aObjectProperty: TRttiProperty; aFlatFileItemAttribute: TFlatFileItemAttribute);
begin
  ObjectInstance := aObjectInstance;
  ObjectProperty := aObjectProperty;
  FlatFileItemAttribute := aFlatFileItemAttribute;

  // make sure the record identifier is set to whatever is defined in the attribute
  if FlatFileItemAttribute.RecordIdentifier.Trim() <> string.Empty then
    ObjectProperty.SetValue(ObjectInstance, FlatFileItemAttribute.RecordIdentifier);
end;

function TFlatFileModelPropertyRecord.GetValue: TValue;
begin
  result := ObjectProperty.GetValue(ObjectInstance);
end;

end.
