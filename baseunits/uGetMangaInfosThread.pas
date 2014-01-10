{
        File: SubThread.pas
        License: GPLv2
        This unit is a part of Free Manga Downloader

        -----------------

        This class allows us to get infomation on certain site and shows it
        in FMD's Manga infos tab.
}

unit uGetMangaInfosThread;

{$mode delphi}

interface

uses
  Classes, SysUtils, Graphics, Dialogs,
  uBaseUnit, uData, uDownloadsManager, uFMDThread;

type
  TGetMangaInfosThread = class(TFMDThread)
  protected
    FMangaListPos: Integer;
    FCover: TPicture;
    FTitle,
    FWebsite,
    FLink : String;
    FInfo : TMangaInformation;

    // Return TRUE if we can get manga information.
    FGetInfosResult,
    // Flush this thread, means that the result will not be shown.
    FIsFlushed: Boolean;

    procedure   Execute; override;
    procedure   DoGetInfos;

    procedure   MainThreadGetInfos;
    procedure   MainThreadCannotGetInfo;
  public
    constructor Create;
    destructor  Destroy; override;

    property    Title: String read FTitle write FTitle;
    property    Website: String read FWebsite write FWebsite;
    property    Link: String read FLink write FLink;
    property    IsFlushed: Boolean read FIsFlushed write FIsFlushed;
    property    MangaListPos: Integer read FMangaListPos write FMangaListPos;
  end;

implementation

uses
  frmMain;

// ----- Protected methods -----

procedure   TGetMangaInfosThread.DoGetInfos;

  function  GetMangaInfo(const URL, website: String): Boolean;
  var
    selectedWebsite: String;
    filterPos      : Cardinal;
    times          : Cardinal;
  begin
    Result:= FALSE;

    if mangaListPos > -1 then
    begin
      filterPos:= MainForm.dataProcess.GetPos(mangaListPos);
      FInfo.mangaInfo.title:= MainForm.dataProcess.Title.Strings[filterPos];
    end;

    FInfo.isGenerateFolderChapterName:= MainForm.cbOptionGenerateChapterName.Checked;
    FInfo.isRemoveUnicode:= MainForm.cbOptionPathConvert.Checked;

    if FInfo.GetInfoFromURL(website, URL, 2)<>NO_ERROR then
    begin
      FInfo.Free;
      exit;
    end;

    // fixed
    if FMangaListPos > -1 then
    begin
      if website = MainForm.cbSelectManga.Items[MainForm.cbSelectManga.ItemIndex] then
      begin
        if sitesWithoutInformation(website) then
        begin
          FInfo.mangaInfo.authors:= MainForm.DataProcess.Param[filterPos, DATA_PARAM_AUTHORS];
          FInfo.mangaInfo.artists:= MainForm.DataProcess.Param[filterPos, DATA_PARAM_ARTISTS];
          FInfo.mangaInfo.genres := MainForm.DataProcess.Param[filterPos, DATA_PARAM_GENRES];
          FInfo.mangaInfo.summary:= MainForm.DataProcess.Param[filterPos, DATA_PARAM_SUMMARY];
        end;
        FInfo.SyncInfoToData(MainForm.DataProcess, filterPos);
      end;
    end;
    Result:= TRUE;
  end;

begin
  if MainForm.cbSelectManga.ItemIndex < 0 then exit;

  if NOT GetMangaInfo(link, website) then
  begin
    Synchronize(MainThreadCannotGetInfo);
    exit;
  end;

  FCover.Clear;
  if (OptionEnableLoadCover) AND (Pos('http://', FInfo.mangaInfo.coverLink) > 0) then
    FGetInfosResult:= GetPage(TObject(FCover), FInfo.mangaInfo.coverLink, 1, TRUE)
  else
    FGetInfosResult:= FALSE;
  Synchronize(MainThreadGetInfos);
end;

procedure   TGetMangaInfosThread.Execute;
begin
  while isSuspended do Sleep(32);

  DoGetInfos;
end;

procedure   TGetMangaInfosThread.MainThreadCannotGetInfo;
begin
  if IsFlushed then exit;
  MessageDlg('', stDlgCannotGetMangaInfo,
               mtInformation, [mbYes], 0);
  MainForm.rmInformation.Clear;
  MainForm.itAnimate.Enabled:= FALSE;
  MainForm.pbWait.Visible:= FALSE;
end;

procedure   TGetMangaInfosThread.MainThreadGetInfos;
begin
  if IsFlushed then exit;
  TransferMangaInfo(MainForm.mangaInfo, FInfo.mangaInfo);
  MainForm.ShowInformation(FTitle, FWebsite, FLink);
  if FGetInfosResult then
  begin
    try
      MainForm.imCover.Picture.Assign(FCover);
    except
      FCover.Clear;
    end;
  end;
end;

// ----- Public methods -----

constructor TGetMangaInfosThread.Create;
begin
  FreeOnTerminate:= TRUE;
  FIsFlushed     := FALSE;
  FInfo          := TMangaInformation.Create;
  FCover         := MainForm.mangaCover;

  inherited Create(FALSE);
end;

destructor  TGetMangaInfosThread.Destroy;
begin
  FInfo.Free;
  inherited Destroy;
end;

end.
