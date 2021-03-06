VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "vb_ODBC"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit
' vb_ODBC
'Copyright (c) 2016 mmYYmmdd

'*********************************************************************************
' ODBC接続
' --------------------------------------------------------------------------------
'   Function        connect             接続文字列を発行してデータベースに接続
'   Sub             disconnect          接続断
'   Sub             disconnect_all      すべてのオブジェクトの接続を断
'   Function        setTimeout          タイムアウトする秒数を設定
'   Sub             clear               ヘッダ（カラム）データとテーブルデータを消去
'   Property Get    last_connected      最後に成功した接続文字列もしくはエラー情報の取得
'   Property Get    last_SQL            最後に発行されたSQL文字列の取得
'   Property Get    last_elapsed        最後に発行されたSELECT文でかかった時間 (ミリ秒)
'   Property Get    last_execError      最後に発行されたexec文のエラー行とエラー内容
'   Property Get    last_queryError     最後に発行されたselect文等のエラー
'   Function        tableList           テーブル一覧取得
'   Function        tableAttribute      テーブルの Attribute
'   Function        read_header         Select文を発行してヘッダ（カラム）情報をメンバに格納する
'   Function        get_header          メンバに格納されたヘッダ（カラム）情報を取得する
'   Function        select_flat         Select文を発行して2次元配列としてメンバに格納する
'   Function        select_rowWise      Select文を発行して行の配列としてメンバに格納する
'   Function        select_columnWise   Select文を発行して列の配列としてメンバに格納する
'   Function        select_map          Select文を発行して行ごとにコールバックを呼ぶ
'   Function        exec                insert文やdelete文を実行する
'   Sub             autoCommit          AUTO COMMIT 設定（デフォルトでは、True:AutoCommit）
'   Sub             rollback            トランザクションのロールバック（AUTO COMMIT設定=Falseの時のみ意味あり）
'   Sub             commit              トランザクションのコミット（AUTO COMMIT設定=Falseの時のみ意味あり）
'   Function        textOut             テキストファイル出力
'   Function        rowSize             テーブルのレコード数
'   Function        colSize             テーブルのカラム数（rowSize = 0の場合でもカラム数 > 0 はあり得る）
'   Function        get_data            Select したテーブルデータのコピーを返す
'   Function        move_data           Select したテーブルデータをmoveして返す
'   Function        insert_expr         insert文
'   Function        insert_expr_        insert文（jag配列または2次元配列）
'   Function        bulk_insert_expr    バルクInsert文（複数行）
'   Function        SQLDrivers          インストールされているODBCドライバ配列を返す
'   Function        excel_expr          Excelブックに接続するための接続文字列
'   Function        mdb_expr            accessdbの接続文字列
'   Function        sqlServer_expr      SQL Serverの接続文字列
'*********************************************************************************

Private Declare PtrSafe Sub terminateODBC Lib "vbODBC.dll" (ByVal n As Long)

Private Declare PtrSafe Sub terminateODBC_all Lib "vbODBC.dll" ()

Private Declare PtrSafe Function initODBC Lib "vbODBC.dll" ( _
                                        ByRef n As Long, _
                                ByRef rawStr As Variant) As Long

Private Declare PtrSafe Function selectODBC Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                            ByRef SQL As Variant, _
                        ByRef header As Variant) As Variant

Private Declare PtrSafe Function selectODBC_rowWise Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef SQL As Variant, _
                            ByRef header As Variant) As Variant

Private Declare PtrSafe Function selectODBC_columnWise Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef SQL As Variant, _
                            ByRef header As Variant) As Variant

Private Declare PtrSafe Function selectODBC_map Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef SQL As Variant, _
                            ByRef header As Variant, _
                        ByVal p_callback As LongPtr, _
                    ByRef param As Variant) As Long

Private Declare PtrSafe Function columnAttributes Lib "vbODBC.dll" _
                                    (ByVal n As Long, _
                                ByRef SQL As Variant) As Variant

Private Declare PtrSafe Function execODBC Lib "vbODBC.dll" _
                                    (ByVal n As Long, _
                                ByRef SQLs As Variant) As Variant

Private Declare PtrSafe Function executeODBC_mark Lib "vbODBC.dll" _
                                    (ByVal n As Long, _
                                ByRef SQL As Variant, _
                            ByVal p_callback As LongPtr, _
                        ByRef vbtypes As Variant, _
                    ByRef Params As Variant) As Long

Private Declare PtrSafe Sub set_autoCommit Lib "vbODBC.dll" _
                                    (ByVal n As Long, _
                                ByVal autoCommit As Long)
                                
Private Declare PtrSafe Function rollbackODBC Lib "vbODBC.dll" _
                                    (ByVal n As Long) As Variant
                                
Private Declare PtrSafe Function commitODBC Lib "vbODBC.dll" _
                                    (ByVal n As Long) As Variant
                                
Private Declare PtrSafe Function table_list_all Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef schemaName As Variant) As Variant

Private Declare PtrSafe Function columnAttributes_all Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef schemaName As Variant, _
                            ByRef tableName As Variant) As Variant

Private Declare PtrSafe Function setQueryTimeout Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByVal sec As Long) As Long
                                
Private Declare PtrSafe Function getStatementError Lib "vbODBC.dll" ( _
                                    ByVal n As Long) As Variant

Private Declare PtrSafe Function textOutODBC Lib "vbODBC.dll" ( _
                                            ByVal n As Long, _
                                        ByRef SQL_expr As Variant, _
                                    ByRef fileName As Variant, _
                                ByRef Delimiter As Variant, _
                            ByVal quote As Boolean, _
                        ByVal append As Boolean, _
                    ByVal codepage_ As Long, _
                ByVal topN As Long, _
            ByVal flushMB As Long, _
        ByVal CrLf As Boolean) As Long

Private Declare PtrSafe Function SQLGetInstalledDrivers Lib "odbccp32.dll" ( _
                                            ByVal buf As String, _
                                        ByVal cbBufMax As Integer, _
                                    ByRef pcchBufOut As Integer) As Byte

Private Declare PtrSafe Function GetTickCount Lib "kernel32.dll" () As Long

Private connectionString    As String    ' 接続文字列もしくは接続エラー情報
Private mySQL_              As String
Private myheader_           As Variant
Private mydata_             As Variant
Private rowSize_ As Long, colSize_ As Long
Private myErrorNo_          As Variant
Private myNo_               As Long
Private laptime_            As Long

Private Sub Class_Initialize()
    myNo_ = -1
End Sub

Private Sub Class_Terminate()
    disconnect
    clear
End Sub

' 接続文字列を発行してデータベースに接続
Public Function connect(ByVal connectionExpr As String) As Boolean
    Dim expr As Variant:    expr = connectionExpr
    connect = (0 <= initODBC(myNo_, expr))
    If connect Then
        connectionString = connectionExpr
    Else
        connectionString = expr
    End If
End Function

' 接続断
Public Sub disconnect()
    Call terminateODBC(myNo_)
End Sub

' すべてのオブジェクトを接続断
Public Sub disconnect_all()
    Call terminateODBC_all
End Sub

' タイムアウトする秒数を設定
Public Function setTimeout(ByVal s As Long) As Boolean
    setTimeout = (0 < setQueryTimeout(myNo_, s))
End Function

' ヘッダ（カラム）データとテーブルデータを消去
Public Sub clear()
    myheader_ = Empty
    mydata_ = Empty
    rowSize_ = 0
    colSize_ = 0
End Sub

' 最後に成功した接続文字列もしくはエラー情報の取得
Public Property Get last_connected() As String
    last_connected = connectionString
End Property

' 最後に発行されたSQL文字列の取得
Public Property Get last_SQL() As String
    last_SQL = mySQL_
End Property

' 最後に発行されたSELECT文でかかった時間（ミリ秒）
Public Property Get last_elapsed() As Long
    last_elapsed = laptime_
End Property

'最後に発行されたexec文のエラー行とエラー内容
Public Property Get last_execError() As Variant
    last_execError = myErrorNo_
End Property

'最後に発行されたselect文等のエラー
Public Property Get last_queryError() As Variant
    last_queryError = getStatementError(myNo_)
End Property


' テーブル一覧取得
Function tableList(Optional ByRef schemaName As Variant, _
                        Optional ByVal type_ As String = "") As Variant
    Dim ret As Variant
    ret = table_list_all(myNo_, IIf(IsMissing(schemaName), "", schemaName))
    If IsEmpty(ret(0)) Then Exit Function
    tableList = catC(catC(ret(0), ret(1)), ret(2))
    If type_ <> "" Then
        tableList = filterR(tableList, _
                mapF(p_Like(p_StrConv(, vbLowerCase), StrConv(type_, vbLowerCase)), ret(2)))
    End If
End Function

' テーブルの Attribute
' 列名、型名、データ長、精度、属性（1:キー, -1:Nullable, 0:他）
Public Function tableAttribute(ByRef schemaName As Variant, _
                            ByRef tableName As Variant) As Variant
    Dim tmp As Variant
    tmp = columnAttributes_all(myNo_, IIf(IsMissing(schemaName), "", schemaName), tableName)
    If IsEmpty(tmp(0)) Then Exit Function
    tmp(4) = mapF(p_mult(-1), tmp(4))
    If 0 < sizeof(tmp(6)) Then
        tmp(4) = zipWith(p_plus, tmp(4), foldl1(p_max, product_set(p_equal, tmp(0), tmp(6)), 2))
    End If
    Dim s As Variant:   s = sortIndex(mapF(p_CLng, tmp(5)))
    tableAttribute = subM(foldl1(p_catC, move_many(tmp(0), tmp(1), tmp(2), tmp(3), tmp(4))), s)
End Function

' Select文を発行してヘッダ（カラム）情報をメンバに格納する
Public Function read_header(ByVal sqlExpr As String) As vb_ODBC
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    myheader_ = columnAttributes(myNo_, sqlExpr)
    If 0 < sizeof(myheader_) Then
        myheader_ = catC(myheader_(0), myheader_(1))
    End If
    laptime_ = GetTickCount() - laptime_
    Set read_header = Me
End Function

' メンバに格納されたヘッダ（カラム）情報を取得する
Public Function get_header(Optional ByVal transpose_ As Boolean = False) As Variant
    If transpose_ Then
        get_header = transpose(myheader_)
    Else
        get_header = myheader_
    End If
End Function

' Select文を発行して2次元配列としてメンバに格納する
Public Function select_flat(ByVal sqlExpr As String) As vb_ODBC
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    mydata_ = selectODBC(myNo_, sqlExpr, myheader_)
    rowSize_ = sizeof(mydata_, 1)
    colSize_ = sizeof(myheader_(0), 1)
    myheader_ = catC(myheader_(0), myheader_(1))
    laptime_ = GetTickCount() - laptime_
    Set select_flat = Me
End Function

' Select文を発行して行の配列としてメンバに格納する
Public Function select_rowWise(ByVal sqlExpr As String) As vb_ODBC
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    mydata_ = selectODBC_rowWise(myNo_, sqlExpr, myheader_)
    rowSize_ = sizeof(mydata_, 1)
    colSize_ = sizeof(myheader_(0), 1)
    myheader_ = catC(myheader_(0), myheader_(1))
    laptime_ = GetTickCount() - laptime_
    Set select_rowWise = Me
End Function

' Select文を発行して列の配列としてメンバに格納する
Public Function select_columnWise(ByVal sqlExpr As String) As vb_ODBC
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    mydata_ = selectODBC_columnWise(myNo_, sqlExpr, myheader_)
    colSize_ = sizeof(myheader_(0), 1)
    myheader_ = catC(myheader_(0), myheader_(1))
    rowSize_ = 0
    If 0 < colSize_ Then
        If 0 < sizeof(mydata_) Then
            rowSize_ = sizeof(mydata_(0), 1)
        End If
    End If
    laptime_ = GetTickCount() - laptime_
    Set select_columnWise = Me
End Function

' Select文を発行して行ごとにコールバックを呼ぶ
' コールバックのシグニチャは以下の通り。（戻り値が0だとFetch終了）
' CallBack(ByVal 行番号 As LongPtr, ByRef レコード As VARIANT, ByRef 任意 As VARIANT) As Long
Public Function select_map(ByVal sqlExpr As String, _
                        ByVal p_callback As LongPtr, _
                    ByRef param As Variant) As Long
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    select_map = selectODBC_map(myNo_, sqlExpr, myheader_, p_callback, param)
    myheader_ = catC(myheader_(0), myheader_(1))
    laptime_ = GetTickCount() - laptime_
End Function

' insert文やdelete文を実行する
Public Function exec(ByRef sqlExpr As Variant) As vb_ODBC
    laptime_ = GetTickCount()
    If IsArray(sqlExpr) Then
        myErrorNo_ = execODBC(myNo_, sqlExpr)
    Else
        myErrorNo_ = execODBC(myNo_, VBA.Array(sqlExpr))
    End If
    laptime_ = GetTickCount() - laptime_
    Set exec = Me
End Function

' insert文やdelete文を実行する
Public Function execute_mark(ByRef sqlExpr As Variant, _
                    ByVal callback As LongPtr, ByRef vbtypes As Variant, ByRef data As Variant) As Long 'vb_ODBC
    laptime_ = GetTickCount()
    'myErrorNo_
    execute_mark = executeODBC_mark(myNo_, sqlExpr, callback, vbtypes, data)
    laptime_ = GetTickCount() - laptime_
    'Set execute_mark = Me
End Function

'AUTO COMMIT 設定（デフォルトでは、True:AutoCommit）
Public Sub autoCommit(ByVal B As Boolean)
    Call set_autoCommit(myNo_, IIf(B, 1, 0))
End Sub

' トランザクションのロールバック（AUTO COMMIT設定=Falseの時のみ意味あり）
Public Sub rollback()
    myErrorNo_ = rollbackODBC(myNo_)
End Sub

' トランザクションのコミット（AUTO COMMIT設定=Falseの時のみ意味あり）
Public Sub commit()
    myErrorNo_ = commitODBC(myNo_)
End Sub

'---------------------------------------------------------------
        ' 文字変換用コードページ
        Private Function getCodePage_(ByVal cp As String) As Long
            Select Case StrConv(cp, vbUpperCase + vbNarrow)
            Case "UTF-16", "UTF16", "UTF-16-LE", "UTF16-LE":
                                                getCodePage_ = 1200
            Case "UTF-8", "UTF8":               getCodePage_ = 65001
            Case "UTF-8N", "UTF8N":             getCodePage_ = -65001
            Case "UTF-7", "UTF7":               getCodePage_ = 65000
            Case "ANSI":                        getCodePage_ = 1252  'ANSI(1252)
            Case "SJIS", "S-JIS", "SHIFT-JIS":  getCodePage_ = 932
            Case "MAC":                         getCodePage_ = 2
            Case "OEM":                         getCodePage_ = 1
            Case "SYMBOL", "SYMBOL42":          getCodePage_ = 42
            Case Else
                If IsNumeric(cp) Then getCodePage_ = CLng(cp) Else getCodePage_ = 65001
            End Select
        End Function
'---------------------------------------------------------------

'テキストファイル出力
Public Function textOut(ByVal sqlExpr As String, _
                        ByVal fileName As String, _
                        ByVal codepage As String, _
                        Optional ByVal Delimiter As String = ",", _
                        Optional ByVal quote As Boolean = False, _
                        Optional ByVal append As Boolean = False, _
                        Optional ByVal topN As Long = -1, _
                        Optional ByVal flushMB As Long = -1, _
                        Optional ByVal CrLf As Boolean = True) As Long
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    textOut = textOutODBC(myNo_, sqlExpr, fileName, Delimiter, quote, append, getCodePage_(codepage), topN, flushMB, CrLf)
    laptime_ = GetTickCount() - laptime_
End Function

' テーブルのレコード数
Public Function rowSize() As Long
    rowSize = rowSize_
End Function

' テーブルのカラム数
Public Function colSize() As Long
    colSize = colSize_
End Function

' Select したテーブルデータのコピーを返す
Public Function get_data() As Variant
    get_data = mydata_
End Function

' Select したテーブルデータをmoveして返す
Public Function move_data() As Variant
    Call swapVariant(move_data, mydata_)
End Function

' insert文
Public Function insert_expr(ByVal table_name As String, _
                                ByRef attr As Variant, _
                                    ByRef values As Variant) As String
    Dim tmp As Variant:     tmp = values
    Dim flag As Variant:    flag = makeM(Haskell_2_stdFun.rowSize(tmp))
    Dim i As Long
    For i = LBound(tmp) To UBound(tmp) Step 1
        flag(i) = 1
        If IsNull(tmp(i)) Or IsEmpty(tmp(i)) Or IsObject(tmp(i)) Or IsArray(tmp(i)) Then
            flag(i) = 0
        ElseIf Not IsNumeric(tmp(i)) Or VarType(tmp(i)) = vbString Then
            If 0 < Len(tmp(i)) Then
                tmp(i) = "'" & Replace(tmp(i), "'", "''") & "'"
            Else
                flag(i) = 0
            End If
        End If
    Next i
    insert_expr = "INSERT INTO " & table_name
    If Dimension(attr) = 1 Then
        insert_expr = insert_expr & " (" & _
                    Join(filterR(attr, flag), ",") & _
                ")"
    End If
    insert_expr = insert_expr & " VALUES(" & _
                Join(filterR(tmp, flag), ",") & _
            ");"
End Function

' insert文（jag配列または2次元配列）
Public Function insert_expr_(ByVal table_name As String, _
                                ByRef attr As Variant, _
                                    ByRef values As Variant) As Variant
    Dim ret As Variant
    ret = makeM(Haskell_2_stdFun.rowSize(values))
    Dim i As Long
    If Dimension(values) = 1 Then
        For i = 0 To UBound(ret) Step 1
            ret(i) = insert_expr(table_name, attr, getNth_b(values, i))
        Next i
    Else
        For i = 0 To UBound(ret) Step 1
            ret(i) = insert_expr(table_name, attr, selectRow_b(values, i))
        Next i
    End If
    swapVariant insert_expr_, ret
End Function

' バルクInsert文（複数行）
' max_record : ひとつのSQL文でINSERTできる最大行
Public Function bulk_insert_expr(ByVal table_name As String, _
                                    ByRef attr As Variant, _
                                        ByRef values As Variant, _
                                            ByVal max_record As Long) As Variant
    Dim v As Variant, i As Long
    v = makeM(Haskell_2_stdFun.rowSize(values))
    If Dimension(values) = 1 Then
        For i = 0 To UBound(v) Step 1
            v(i) = bulk_insert_expr_1(getNth_b(values, i))
        Next i
    Else
        For i = 0 To UBound(v) Step 1
            v(i) = bulk_insert_expr_1(selectRow_b(values, i))
        Next i
    End If
    Dim ret As Variant: ret = makeM((sizeof(v) + max_record - 1) \ max_record)
    For i = 0 To UBound(ret) Step 1
        ret(i) = "INSERT INTO " & table_name & " ("
        ret(i) = ret(i) & Join(attr, ",") & ") VALUES "
        ret(i) = ret(i) & Join(subV(v, a__o(i * max_record, min_fun(sizeof(v), (i + 1) * max_record))), ",") & ";"
    Next i
    Call swapVariant(bulk_insert_expr, ret)
End Function
    
    Private Function bulk_insert_expr_1(ByRef record As Variant) As String
        Call changeLBound(record, 0)
        Dim i As Long
        For i = 0 To UBound(record) Step 1
            If IsNull(record(i)) Or IsEmpty(record(i)) Or IsObject(record(i)) Or IsArray(record(i)) Then
                record(i) = "NULL"
            ElseIf Not IsNumeric(record(i)) Or VarType(record(i)) = vbString Then
                If 0 < Len(record(i)) Then
                    record(i) = "'" & Replace(record(i), "'", "''") & "'"
                End If
            End If
            If Len(record(i)) = 0 Then record(i) = "NULL"
        Next i
        bulk_insert_expr_1 = "(" & Join(record, ",") & ")"
    End Function

' インストールされているODBCドライバ配列を返す
Public Function SQLDrivers(Optional ByVal bufLen = 0) As Variant
    Dim buf As String, ret As Byte, retL As Integer
    buf = Space(IIf(0 < bufLen, bufLen, 2 * 1024))
    ret = SQLGetInstalledDrivers(buf, Len(buf), retL)
    SQLDrivers = Split(Left(buf, retL - 2), vbNullChar)
End Function

' Excelブックに接続するための接続文字列
Public Function excel_expr(ByVal bookName As String, _
                           Optional ByVal readonly As Boolean = True) As String
    Dim drivers As Variant
    Dim i As Variant
    excel_expr = "Microsoft Excel Driver"
    drivers = SQLDrivers
    permutate drivers, reverse(sortIndex(mapF(p_len, drivers)))
    i = find_pred(p_equal(excel_expr, p_left(, Len(excel_expr))), drivers)
    If i <= UBound(drivers) Then
        excel_expr = "DBA=R; Driver={" & drivers(i) & "}; DBQ="
        excel_expr = excel_expr & bookName
        excel_expr = excel_expr & IIf(readonly, ";", "; ReadOnly=False;")
    Else
        excel_expr = ""
    End If
    '               SELECT * FROM [Sheet1$A1:D10]
    '               INSERT INTO [Sheet1$A1:D10] VALUES(
End Function

' accessdbの接続文字列
Public Function mdb_expr(ByVal dbName As String) As String
    Dim drivers As Variant
    Dim i As Variant
    mdb_expr = "DBA=R; Driver={Microsoft Access Driver (*.mdb, *.accdb)}; DBQ="
    mdb_expr = mdb_expr & dbName
    '               SELECT * FROM MSysNameMap
End Function

' SQL Serverの接続文字列
Public Function sqlServer_expr(ByVal server As String, _
                               ByVal dbName As String, _
                               Optional ByVal uid As String = "", _
                               Optional ByVal pwd As String = "") As String
    Dim drivers As Variant
    Dim i As Variant
    sqlServer_expr = "Driver={SQL Server Native Client 11.0};"
    If 0 = Len(uid) Then
        sqlServer_expr = sqlServer_expr & " Trusted_Connection=YES;"
    End If
    sqlServer_expr = sqlServer_expr & " Server=" & server & "; DATABASE=" & dbName
    If 0 < Len(uid) Then
        sqlServer_expr = sqlServer_expr & "; UID=" & uid
    End If
    If 0 < Len(pwd) Then
        sqlServer_expr = sqlServer_expr & "; PWD=" & pwd
    End If
    '               SELECT * FROM sysobjects WHERE xtype = 'U'
End Function


