VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "vb_ADODBs"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit
' vb_ADODBs
'Copyright (c) 2017 mmYYmmdd

'*********************************************************************************
' ADODB�ڑ��i�ق�INSERT�ɓ����j
' ADO(Microsoft AitiveX Data Objects) ����� ADOX(Microsoft ADO Ext.)���Q�Ɛݒ�
' --------------------------------------------------------------------------------
' Function  connect             �ڑ�������𔭍s���ăf�[�^�x�[�X�ɐڑ�
' Sub       disconnect          �ڑ��f
' Function  tableExists         �e�[�u�����݊m�F
' Function  insert              INSERT�i�P�s�j
' Function  insert_             INSERT�i�����s�j
' Function  tableInstance       �����ݒ�p��ADOX.Table �I�u�W�F�N�g��Ԃ�
' Function  createTable         �e�[�u������
' Function  renameTable         �e�[�u�����O�ύX
' Function  dropTable           �e�[�u���폜
' Function  truncateTable       �e�[�u���S�s�폜
' Function  mdb_expr            accessdb�̐ڑ�������
' Function  excel_expr          Excel�u�b�N�̐ڑ�������
' Function  sqlServer_expr      SQL Server�̐ڑ�������
'*********************************************************************************

Private Declare PtrSafe Function SQLGetInstalledDrivers Lib "odbccp32.dll" ( _
                                                ByVal buf As String, _
                                            ByVal cbBufMax As Integer, _
                                        ByRef pcchBufOut As Integer) As Byte

Private Declare PtrSafe Function GetTickCount Lib "kernel32.dll" () As Long

    Private mycon_              As ADODB.Connection
    Const providerExpr As String = "Provider=Microsoft.Ace.OLEDB.12.0;"

Private Sub Class_Initialize()
    Set mycon_ = New ADODB.Connection
End Sub

Private Sub Class_Terminate()
    disconnect
    Set mycon_ = Nothing
End Sub

' �ڑ�������𔭍s���ăf�[�^�x�[�X�ɐڑ�
Public Function connect(ByVal connectionExpr As String, _
                    Optional ByVal provider As String = "MSDASQL") As Boolean
    connect = False
    disconnect
    On Error Resume Next
    If StrConv(connectionExpr, vbLowerCase) Like "*provider*=*" Then
        mycon_.Open connectionExpr
    Else
        mycon_.Open "Provider=" & provider & ";" & connectionExpr
    End If
    connect = mycon_.State <> adStateClosed
    ' https://msdn.microsoft.com/ja-jp/library/cc426812.aspx
End Function

' �ڑ��f
Public Sub disconnect()
    If mycon_.State <> adStateClosed Then mycon_.Close
End Sub

' �e�[�u�����݊m�F
Public Function tableExists(ByVal tbname As String) As Boolean
    tableExists = False
    If mycon_.State = adStateClosed Then Exit Function
    Dim z As ADOX.Table
    With New ADOX.Catalog
        .ActiveConnection = mycon_
        For Each z In .Tables
            If z.Name = tbname Then
                tableExists = True
                Exit For
            End If
        Next z
    End With
End Function

' INSERT�i�P�s�j
' Attr�͗񖼂������͗�̏����i0�X�^�[�g�j�̔z��
Public Function insert(ByVal tableName As String, _
                       ByRef attr As Variant, _
                       ByRef values As Variant) As Boolean
    insert = False
    If mycon_.State = adStateClosed Then Exit Function
    If sizeof(attr) <> sizeof(values) Then Exit Function
    If 0 = Dimension(values) Or 2 < Dimension(values) Then Exit Function
    Dim flag As Variant
    flag = mapF(p_is_valid, values)
    With New ADODB.Recordset
        .source = tableName
        .ActiveConnection = mycon_
        .LockType = adLockOptimistic
        .Open
        .AddNew filterR(attr, flag), filterR(values, flag)
        .Update
        .Close
    End With
    insert = True
End Function

' INSERT�i�����s�j
' Attr�͗񖼂������͗�̏����i0�X�^�[�g�j�̔z��
Public Function insert_(ByVal tableName As String, _
                        ByRef attr As Variant, _
                        ByRef values As Variant) As Variant
    If mycon_.State = adStateClosed Then Exit Function
    If 0 = Dimension(values) Or 2 < Dimension(values) Then Exit Function
    Dim ret As Variant: ret = makeM(sizeof(values, 1))
    Dim flag As Variant
    Dim i As Long, k As Long: k = 0
    With New ADODB.Recordset
        .source = tableName
        .ActiveConnection = mycon_
        .LockType = adLockOptimistic
        .Open
        Select Case Dimension(values)
        Case 1:
            For i = LBound(values) To UBound(values) Step 1
                If sizeof(attr) = sizeof(values(i)) Then
                    flag = mapF(p_is_valid, values(i))
                    .AddNew filterR(attr, flag), filterR(values(i), flag)
                    ret(k) = True
                Else
                    ret(k) = False
                End If
                k = k + 1
            Next i
            .Update
            .Close
        Case 2:
            If sizeof(attr) <> sizeof(values, 2) Then
                .Close
                Exit Function
            End If
            Dim tmp As Variant
            For i = LBound(values, 1) To UBound(values, 1) Step 1
                tmp = selectRow(values, i)
                flag = mapF(p_is_valid, tmp)
                .AddNew filterR(attr, flag), filterR(tmp, flag)
                ret(k) = True
                k = k + 1
            Next i
            .Update
            .Close
        End Select
    End With
    Call swapVariant(ret, insert_)
End Function

' adBoolean         11      �u�[���l�^
' adCurrency         6      �ʉ݌^
' adDate             7      ���t�����^
' adDouble           5      �{���x���������_���^
' adGUID            72      �I�[�g�i���o�[�^
' adInteger          3      �������^
' adLongVarWChar   203      �����^
' adSingle           4      �P���x���������_���^
' adSmallInt         2      �����^
' adVarWChar       202      �e�L�X�g�^

' �����ݒ�p��ADOX.Table �I�u�W�F�N�g��Ԃ�
' �icreateTable�̈����Ǝg�p���邱�Ƃ�z��j
Public Function tableInstance(ByVal tName As String) As ADOX.Table
    Set tableInstance = New ADOX.Table
    tableInstance.Name = tName
    'TB.Columns.append "�w�Дԍ�", adInteger
    'TB.Columns.append "����", adVarWChar, 30
    'TB.Columns.Item(i).Attributes = adColNullable
End Function

' �e�[�u������
Public Function createTable(ByVal tb As ADOX.Table) As Boolean
    createTable = False
    If mycon_.State = adStateClosed Then Exit Function
    With New ADOX.Catalog
        .ActiveConnection = mycon_
        .Tables.append tb
    End With
    createTable = True
End Function

' �e�[�u�����O�ύX
Public Function renameTable(ByVal tbname_old As String, ByVal tbname_new As String) As BookmarkEnum
    renameTable = False
    If mycon_.State = adStateClosed Then Exit Function
    With New ADOX.Catalog
        .ActiveConnection = mycon_
        .Tables.Item(tbname_old).Name = tbname_new
    End With
    renameTable = True
End Function

' �e�[�u���폜
Public Function dropTable(ByVal tbname As String) As Boolean
    dropTable = False
    If mycon_.State = adStateClosed Then Exit Function
    With New ADOX.Catalog
        .ActiveConnection = mycon_
        .Tables.Delete tbname
    End With
    dropTable = True
End Function

' �e�[�u���S�s�폜
Public Function truncateTable(ByVal tbname As String) As Long
    If mycon_.State = adStateClosed Then Exit Function
    mycon_.Execute "DELETE * FROM " & tbname, truncateTable, adExecuteNoRecords
    ' �i���R�[�h�Z�b�g��Delete����MoveNext������葬���͗l�j
End Function

' accessdb�̐ڑ�������
Public Function mdb_expr(ByVal dbName As String) As String
    mdb_expr = providerExpr
    mdb_expr = mdb_expr & "Data Source=" & dbName & ";"
End Function

' Excel�u�b�N�̐ڑ�������
Public Function excel_expr(ByVal bookName As String, _
                           Optional header As Boolean = True) As String
    excel_expr = providerExpr & _
                 "Data Source=" & bookName & ";" & _
                 "Extended Properties=""[[EP]];HDR=[[HDR]]"";"
    Dim Extended_Properties As String
    Select Case Right(bookName, 4)
        Case ".xls":    Extended_Properties = "Excel 8.0"
        Case "xlsx":    Extended_Properties = "Excel 12.0 Xml"
        Case "xlsb":    Extended_Properties = "Excel 12.0"
        Case "xlsm":    Extended_Properties = "Excel 12.0 Macro"
    End Select
    excel_expr = Replace(excel_expr, "[[EP]]", Extended_Properties)
    excel_expr = Replace(excel_expr, "[[HDR]]", IIf(header, "YES", "NO"))
End Function

' SQL Server�̐ڑ�������
Public Function sqlServer_expr(ByVal server As String, _
                               ByVal dbName As String, _
                               Optional ByVal uid As String = "", _
                               Optional ByVal pwd As String = "") As String
    Dim drivers As Variant
    Dim i As Variant
    sqlServer_expr = "Provider=SQLOLEDB;Driver={SQL Server Native Client 11.0};"
    If 0 = Len(uid) Then
        sqlServer_expr = sqlServer_expr & "Trusted_Connection=YES;"
    End If
    sqlServer_expr = sqlServer_expr & "Server=" & server & ";" _
                                    & "DATABASE=" & dbName & ";"
    If 0 < Len(uid) Then
        sqlServer_expr = sqlServer_expr & "UID=" & uid & ";"
    End If
    If 0 < Len(pwd) Then
        sqlServer_expr = sqlServer_expr & "PWD=" & pwd & ";"
    End If
    ' select * from sysobjects where xtype = 'U'
End Function