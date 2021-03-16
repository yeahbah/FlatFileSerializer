unit uFlatFileExceptions;

interface

uses
  SysUtils;

type
  ERecordSizeMismatch = class(Exception);

  EInvalidRecordParentClass = class(Exception);

  EUndefinedRecordIdentifier = class(Exception);

  EMultipleRecordIdentifier = class(Exception);

implementation

end.
