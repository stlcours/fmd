function   GetMangaGoDirectoryPageNumber: Byte;
  var
    i: Cardinal;
  begin
    Result:= INFORMATION_NOT_FOUND;
    if NOT GetPage(TObject(source), WebsiteRoots[MANGAGO_ID,1] + MANGAGO_BROWSER + '1/', 0) then
    begin
      Result:= NET_PROBLEM;
      source.Free;
      exit;
    end;
    parse.Clear;
    Parser:= TjsFastHTMLParser.Create(PChar(source.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count=0 then
    begin
      source.Free;
      exit;
    end;
    for i:= 0 to parse.Count-1 do
    begin
      if (Pos('class="pagination"', parse.Strings[i])<>0)  then
      begin
        s:= TrimLeft(TrimRight(GetAttributeValue(GetTagAttribute(parse.Strings[i], 'total='))));
        Page:= StrToInt(s);
        Result:= NO_ERROR;
        source.Free;
        exit;
      end;
    end;
    source.Free;
  end; 