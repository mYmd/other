VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "vb_ODBC"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
' vb_ODBC
'Copyright (c) 2016 mmYYmmdd

'*********************************************************************************
' ODBC接続
' --------------------------------------------------------------------------------
'   Function        connect         接続文字列を発行してデータベースに接続
'   Sub             disconnect      接続断
'   Sub             clear           ヘッダ（カラム）データとテーブルデータを消去
'   Property Get    last_connected  最後に成功した接続文字列の取得
'   Property Get    last_SQL        最後に発行されたSQL文字列の取得
'   Property Get    last_elapsed    最後に発行されたSELECT文でかかった時間 (ミリ秒)
'   Function        read_header     Select文を発行してヘッダ（カラム）情報をメンバに格納する
'   Function        get_header      メンバに格納されたヘッダ（カラム）情報を取得する
'   Function        select_flat     Select文を発行して結果を2次元配列としてメンバに格納する
'   Function        select_zip      Select文を発行して結果をZIP配列としてメンバに格納する
'   Function        rowSize         テーブルのレコード数
'   Function        colSize         テーブルのカラム数
'   Function        get_data        Select したテーブルデータのコピーを返す
'   Function        move_data       Select したテーブルデータをmoveして返す
'   Function        SQLDrivers      インストールされているODBCドライバ配列を返す
'   Function        excel_expr      特定のExcelブックに接続するための接続文字列
'*********************************************************************************

Private Declare PtrSafe Function terminateODBC Lib "vbODBC.dll" (ByVal n As Long) As Long

Private Declare PtrSafe Function initODBC Lib "vbODBC.dll" ( _
                                        ByVal n As Long, _
                                    ByRef rawStr As Variant) As Long

Private Declare PtrSafe Function selectODBC Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef sql As Variant, _
                            Optional ByVal timeOutSec As Long = 0) As Variant

Private Declare PtrSafe Function selectODBC_zip Lib "vbODBC.dll" ( _
                                    ByVal n As Long, _
                                ByRef sql As Variant, _
                            Optional ByVal timeOutSec As Long = 0) As Variant

Private Declare PtrSafe Function columnAttributes Lib "vbODBC.dll" _
                                (ByVal n As Long, ByRef sql As Variant) As Variant

Private Declare PtrSafe Function execODBC Lib "vbODBC.dll" _
                        (ByVal n As Long, ByRef SQLs As Variant) As Long

Private Declare PtrSafe Function SQLGetInstalledDrivers Lib "odbccp32.dll" ( _
                                                ByVal buf As String, _
                                            ByVal cbBufMax As Integer, _
                                        ByRef pcchBufOut As Integer) As Byte

Private Declare PtrSafe Function GetTickCount Lib "kernel32.dll" () As Long

Private connectionString   As String    ' 接続文字列
Private mySQL_       As String
Private myheader_    As Variant
Private mydata_      As Variant
Private myNo_        As Long
Private laptime_     As Long

Private Sub Class_Initialize()
    myNo_ = -1
End Sub

Private Sub Class_Terminate()
    disconnect
    clear
End Sub

' 接続文字列を発行してデータベースに接続
Public Function connect(ByVal connectionExpr As String) As Boolean
    myNo_ = initODBC(myNo_, connectionExpr)
    connect = (0 <= myNo_)
    If connect Then connectionString = connectionExpr
End Function

' 接続断
Public Sub disconnect()
    terminateODBC myNo_
    myNo_ = -1
End Sub

' ヘッダ（カラム）データとテーブルデータを消去
Public Sub clear()
    myheader_ = Empty
    mydata_ = Empty
End Sub

' 最後に成功した接続文字列の取得
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

' Select文を発行してヘッダ（カラム）情報をメンバに格納する
Public Function read_header(ByVal sqlExpr As String) As vb_ODBC
    mySQL_ = sqlExpr
    laptime_ = GetTickCount()
    myheader_ = columnAttributes(myNo_, sqlExpr)
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

' Select文を発行して結果を2次元配列としてメンバに格納する
Public Function select_flat(ByVal sqlExpr As String, Optional ByVal timeOutSec As Long = 0) As vb_ODBC
    mySQL_ = sqlExpr
    read_header sqlExpr
    laptime_ = GetTickCount()
    mydata_ = selectODBC(myNo_, sqlExpr, timeOutSec)
    laptime_ = GetTickCount() - laptime_
    Set select_flat = Me
End Function

' Select文を発行して結果をZIP配列としてメンバに格納する
Public Function select_zip(ByVal sqlExpr As String, Optional ByVal timeOutSec As Long = 0) As vb_ODBC
    mySQL_ = sqlExpr
    read_header sqlExpr
    laptime_ = GetTickCount()
    mydata_ = selectODBC_zip(myNo_, sqlExpr, timeOutSec)
    laptime_ = GetTickCount() - laptime_
    Set select_zip = Me
End Function

' テーブルのレコード数
Public Function rowSize() As Long
    rowSize = Haskell_2_stdFun.rowSize(mydata_)
End Function

' テーブルのカラム数
Public Function colSize() As Long
    colSize = Haskell_2_stdFun.colSize(mydata_)
End Function

' Select したテーブルデータのコピーを返す
Public Function get_data() As Variant
    get_data = mydata_
End Function

' Select したテーブルデータをmoveして返す
Public Function move_data() As Variant
    swapVariant move_data, mydata_
End Function

' インストールされているODBCドライバ配列を返す
Public Function SQLDrivers(Optional ByVal buflen = 0) As Variant
    Dim buf As String, ret As Byte, retL As Integer
    buf = Space(IIf(0 < buflen, buflen, 2 * 1024))
    ret = SQLGetInstalledDrivers(buf, Len(buf), retL)
    SQLDrivers = Split(left(buf, retL - 2), Chr(0))
End Function

' 特定のExcelブックに接続するための接続文字列
Public Function excel_expr(ByVal bookName As String) As String
    Dim drivers As Variant
    Dim i As Variant
    excel_expr = "Microsoft Excel Driver"
    drivers = SQLDrivers
    permutate drivers, reverse(sortIndex(mapF(p_len, drivers)))
    i = find_pred(p_equal(excel_expr), mapF(p_left(, Len(excel_expr)), drivers))
    If i <= UBound(drivers) Then
        excel_expr = "DBA=R; Driver={" & drivers(i) & "}; DBQ="
        excel_expr = excel_expr & bookName
    Else
        excel_expr = ""
    End If
End Function

'----------------------------------------------------
'SQL Server以外
' "DBA=R; Driver={}; DBQ=; UID=; PWD="
'SQL Server
' "Trusted_Connection=YES; Driver={}; DBQ=; UID=; PWD="
'----------------------------------------------------
'Driver={Microsoft Excel Driver (*.xls, *.xlsx, *.xlsm, *.xlsb)}    DBA = R
'   SELECT * FROM [Sheet1$A1:D10]
'----------------------------------------------------
'Microsoft Access Driver (*.mdb,*.accdb)
'Microsoft Excel Driver (*.xls, *.xlsx, *.xlsm, *.xlsb)
'Oracle in OraCleien11g_home1
'SQL Server Native Client 10.0
'----------------------------------------------------