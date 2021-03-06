{
        File: uPacker.pas
        License: GPLv2
        This unit is a part of Free Manga Downloader
}

unit uPacker;

{$mode delphi}

interface

uses
  Classes, FileUtil, Zipper, SysUtils, uBaseUnit, uImg2Pdf;

type
  TPacker = class
  protected
    list: TStringList;
    procedure   OnFileFound(FileIterator: TFileIterator);
  public
    ext,
    Path              : String;
    CompressionQuality: Cardinal;
    procedure   DoZipCbz;
    procedure   DoPdf;
    procedure   Execute;
  end;

implementation

uses
  lazutf8classes;

procedure   TPacker.OnFileFound(FileIterator: TFileIterator);
begin
  list.Add(FileIterator.Filename);
end;

procedure   TPacker.DoZipCbz;
var
  s,
  fPath   : String;
  searcher: TFileSearcher;
  Zip     : TZipper;
  i       : Cardinal;
  fstream : TFileStreamUTF8;
begin
  try
    fPath:= Trim(Path);
    RenameFileUTF8(Path, fPath);
    list:= TStringList.Create;
    searcher:= TFileSearcher.Create;
    searcher.OnFileFound:= OnFileFound;
    searcher.Search(fPath, '*.jpg;*.jpeg;*.png;*.gif;*.db', FALSE, FALSE);

    if list.Count <> 0 then
    begin
      Zip:= TZipper.Create;
      Zip.FileName:= fPath+ext;
      for i:= 0 to list.Count-1 do
      begin
        {$IFDEF WINDOWS}
        s:= StringReplace(list.Strings[i], '/', '\', [rfReplaceAll]);
        {$ELSE}
        s:= list.Strings[i];
        {$ENDIF}
        Zip.Entries.AddFileEntry(s, Format('%s',
                                           [StringReplace(ExtractFileName(list.Strings[i]), ExtractFilePath(list.Strings[i]), '', [])]));
      end;

      fstream:= TFileStreamUTF8.Create(fPath+ext, fmCreate);
      Zip.SaveToStream(fstream);
      fstream.Free;
      Zip.Free;
      for i:= 0 to list.Count-1 do
        DeleteFileUTF8(list.Strings[i]);
      Sleep(128);
      RemoveDirUTF8(fPath);
      if fPath[Length(fPath)] = '/' then
        Delete(fPath, Length(fPath), 1);
      RenameFileUTF8(fPath+ext, Path+ext);
    end;
    searcher.Free;
    list.Free;
  except
    on E: Exception do
      raise E;
  end;
end;

procedure   TPacker.DoPdf;
var
  s,
  fPath   : String;
  searcher: TFileSearcher;
  pdf     : TImg2Pdf;
  i       : Cardinal;
  fstream : TFileStreamUTF8;
begin
  try
   // Path:= FixPath(Path);
    fPath:= Trim(Path);
    RenameFileUTF8(Path, fPath);
    list:= TStringList.Create;
    searcher:= TFileSearcher.Create;
    searcher.OnFileFound:= OnFileFound;
    searcher.Search(fPath, '*.jpg;*.jpeg;*.png;*.gif', FALSE, FALSE);

    if list.Count <> 0 then
    begin
      pdf:= TImg2Pdf.Create;
      pdf.CompressionQuality:= CompressionQuality;
      pdf.Title:= GetLastDir(Path);
     // pdf.FileName:= fPath+ext;
      for i:= 0 to list.Count-1 do
      begin
        {$IFDEF WINDOWS}
        s:= StringReplace(list.Strings[i], '/', '\', [rfReplaceAll]);
        {$ELSE}
        s:= list.Strings[i];
        {$ENDIF}

        // add image to PDF
        pdf.AddImage(s);
      end;

      fstream:= TFileStreamUTF8.Create(fPath+ext, fmCreate);
      pdf.SaveToStream(fstream);
      fstream.Free;
      pdf.Free;
      searcher.Search(fPath, '*.db', FALSE, FALSE);
      for i:= 0 to list.Count-1 do
        DeleteFileUTF8(list.Strings[i]);
      Sleep(128);
      RemoveDirUTF8(fPath);
      if fPath[Length(fPath)] = '/' then
        Delete(fPath, Length(fPath), 1);
      RenameFileUTF8(fPath+ext, Path+ext);
    end;
    searcher.Free;
    list.Free;
  except
    on E: Exception do
      raise E;
  end;
end;

procedure   TPacker.Execute;
begin
  if (ext='.zip') OR (ext='.cbz') then
  begin
    DoZipCbz;
  end
  else
    DoPdf;
end;

end.

