<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Curator.aspx.cs" Inherits="PSPC.Curator" %>

<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="ajaxToolkit" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Pouch SPC Curator</title>
    <style type="text/css">
        .auto-style2 {
            font-family: Arial, Helvetica, sans-serif;
        }
        .auto-style3 {
            text-align: left;
        }
        .auto-style4 {
            margin-top: 11px;
        }
    </style>
    <link href="main.css" rel="stylesheet" type="text/css" />
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>
</head>
<body>
    <form id="form1" runat="server">
    <img src = "images/BioFire-Logo1.jpg" alt="Biofire" />
        <h1>Pouch SPC Curator</h1>
        <div id="updateButtons">
            <asp:Button ID="Button3" runat="server" Text="Input New Run Observation" OnClick="Button3_Click" BackColor="#CCCCCC" />
            <asp:Button ID="Button2" runat="server" Text="Update Previous Run Observation" OnClick="Button2_Click" />
            <asp:Button ID="Button5Link" runat="server" Text="Pouch SPC Charting App" OnClick="Button5Link_Click" />          
        </div>
        <asp:Label ID="CountLabel" runat="server" Text="Runs Not Curated: "></asp:Label>
        <br />
    <div id="TopBox">
        <div id="RunInfo" class="PouchInfo">
            <h4>
            <asp:Label ID="PanelVersion" runat="server" CssClass="auto-style2"></asp:Label>
            </h4>
            <br class="auto-style2" />
            <h4>
            <span class="auto-style2">Pouch Serial Number:</span></h4>
            &nbsp;&nbsp;&nbsp;<ajaxToolkit:ComboBox ID="ComboBox1" runat="server" AutoPostBack="True" OnSelectedIndexChanged="ComboBox1_SelectedIndexChanged" AutoCompleteMode="Suggest" DropDownStyle="DropDownList">
            </ajaxToolkit:ComboBox>
            <br class="auto-style2" />
            <h4>
            <span class="auto-style2">Pouch Lot:</span></h4>
            &nbsp;&nbsp;&nbsp;
            <asp:Label ID="PouchLot" runat="server" CssClass="auto-style2"></asp:Label>
            <br />
            <h4>
            <span class="auto-style2">Instrument:</span></h4>
            &nbsp;&nbsp;&nbsp;
            <asp:Label ID="Instrument" runat="server" CssClass="auto-style2"></asp:Label>
            </div>
        <div id="RunInfo2" class="PouchInfo">
            <h4>
            <span class="auto-style2">Start Time:&nbsp;</span></h4>
            &nbsp;&nbsp;&nbsp; 
            <asp:Label ID="StartTime" runat="server" CssClass="auto-style2"></asp:Label>
            <br class="auto-style2" />
            <h4>
            <span class="auto-style2">Sample ID:</span></h4>
            &nbsp;&nbsp;&nbsp;
            <asp:Label ID="SampleID" runat="server" CssClass="auto-style2"></asp:Label>
            <br class="auto-style2" />
            <h4>
            <span class="auto-style2">Pouch Code:</span></h4>
            &nbsp;&nbsp;&nbsp; 
            <asp:Label ID="PouchCode" runat="server" CssClass="auto-style2"></asp:Label>
        </div>
        </div>
        <asp:Label ID="ExpID" runat="server" Visible="False"></asp:Label>
        <asp:ScriptManager ID="ScriptManager1" runat="server">
        </asp:ScriptManager>
        <br />
        <br />
        <div id="CFbox" class="middleBox">
            <h4>Control Failures</h4>
            <br />
            <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" CellPadding="5" CellSpacing="1" DataSourceID="SqlDataSource1" EmptyDataText="None" HorizontalAlign="Center">
                <Columns>
                    <asp:BoundField DataField="AssayName" HeaderText="Assay" SortExpression="AssayName" />
                    <asp:BoundField DataField="AssayCode" HeaderText="Assay Code" SortExpression="AssayCode" />
                </Columns>
                <HeaderStyle BackColor="Maroon" ForeColor="White" />
            </asp:GridView>
        </div>
        <div id="FPbox" class="middleBox">
            <h4>False Positives</h4>
            <br />
            <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="False" CellPadding="5" CellSpacing="1" DataSourceID="FalsePositives" EmptyDataText="None" HorizontalAlign="Center">
                <Columns>
                    <asp:BoundField DataField="AssayName" HeaderText="Assay" SortExpression="AssayName" />
                    <asp:BoundField DataField="AssayCode" HeaderText="Assay Code" SortExpression="AssayCode" />
                </Columns>
                <HeaderStyle BackColor="Maroon" ForeColor="White" />
            </asp:GridView>
        </div>
        <div id="FNbox" class="middleBox">
            <h4>False Negatives</h4>
            <br />
            <asp:GridView ID="GridView3" runat="server" AutoGenerateColumns="False" CellPadding="5" CellSpacing="1" DataSourceID="FalseNegatives" EmptyDataText="None" HorizontalAlign="Center">
                <Columns>
                    <asp:BoundField DataField="AssayName" HeaderText="Assay" SortExpression="AssayName" />
                    <asp:BoundField DataField="AssayCode" HeaderText="Assay Code" SortExpression="AssayCode" />
                </Columns>
                <HeaderStyle BackColor="Maroon" ForeColor="White" />
            </asp:GridView>
        </div>
        <p>
            <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:CIConnection1 %>" SelectCommand="SELECT [AssayName], [AssayCode] FROM [SPCControlFailures] WHERE ([PouchSerialNumber] = @PouchSerialNumber)">
                <SelectParameters>
                    <asp:ControlParameter ControlID="ComboBox1" Name="PouchSerialNumber" PropertyName="SelectedValue" Type="String" />
                </SelectParameters>
            </asp:SqlDataSource>
            <asp:SqlDataSource ID="FalsePositives" runat="server" ConnectionString="<%$ ConnectionStrings:CIConnection1 %>" SelectCommand="SELECT [AssayName], [AssayCode] FROM [SPCFalsePositives] WHERE ([PouchSerialNumber] = @PouchSerialNumber)">
                <SelectParameters>
                    <asp:ControlParameter ControlID="ComboBox1" Name="PouchSerialNumber" PropertyName="SelectedValue" Type="String" />
                </SelectParameters>
            </asp:SqlDataSource>
            <asp:SqlDataSource ID="FalseNegatives" runat="server" ConnectionString="<%$ ConnectionStrings:CIConnection1 %>" SelectCommand="SELECT [AssayName], [AssayCode] FROM [SPCFalseNegatives] WHERE ([PouchSerialNumber] = @PouchSerialNumber)">
                <SelectParameters>
                    <asp:ControlParameter ControlID="ComboBox1" Name="PouchSerialNumber" PropertyName="SelectedValue" Type="String" />
                </SelectParameters>
            </asp:SqlDataSource>
        </p>
        <div id="PrevRunOb" runat="server">
            <asp:ListView ID="ListView1" runat="server" DataSourceID="PrevObs">
                <AlternatingItemTemplate>
                    <tr style="">
                        <td>
                            <asp:Label ID="Previous_Run_ObservationLabel" runat="server" Text='<%# Eval("[Previous Run Observation]") %>' />
                        </td>
                    </tr>
                </AlternatingItemTemplate>
                <EditItemTemplate>
                    <tr style="">
                        <td>
                            <asp:Button ID="UpdateButton" runat="server" CommandName="Update" Text="Update" />
                            <asp:Button ID="CancelButton" runat="server" CommandName="Cancel" Text="Cancel" />
                        </td>
                        <td>
                            <asp:TextBox ID="Previous_Run_ObservationTextBox" runat="server" Text='<%# Bind("[Previous Run Observation]") %>' />
                        </td>
                    </tr>
                </EditItemTemplate>
                <EmptyDataTemplate>
                    <table runat="server" style="">
                        <tr>
                            <td>No data was returned.</td>
                        </tr>
                    </table>
                </EmptyDataTemplate>
                <InsertItemTemplate>
                    <tr style="">
                        <td>
                            <asp:Button ID="InsertButton" runat="server" CommandName="Insert" Text="Insert" />
                            <asp:Button ID="CancelButton" runat="server" CommandName="Cancel" Text="Clear" />
                        </td>
                        <td>
                            <asp:TextBox ID="Previous_Run_ObservationTextBox" runat="server" Text='<%# Bind("[Previous Run Observation]") %>' />
                        </td>
                    </tr>
                </InsertItemTemplate>
                <ItemTemplate>
                    <tr style="">
                        <td>
                            <asp:Label ID="Previous_Run_ObservationLabel" runat="server" Text='<%# Eval("[Previous Run Observation]") %>' />
                        </td>
                    </tr>
                </ItemTemplate>
                <LayoutTemplate>
                    <table runat="server">
                        <tr runat="server">
                            <td runat="server">
                                <table id="itemPlaceholderContainer" runat="server" border="0" style="">
                                    <tr runat="server" style="">
                                        <th runat="server">Previous Run Observation</th>
                                    </tr>
                                    <tr id="itemPlaceholder" runat="server">
                                    </tr>
                                </table>
                            </td>
                        </tr>
                        <tr runat="server">
                            <td runat="server" style=""></td>
                        </tr>
                    </table>
                </LayoutTemplate>
                <SelectedItemTemplate>
                    <tr style="">
                        <td>
                            <asp:Label ID="Previous_Run_ObservationLabel" runat="server" Text='<%# Eval("[Previous Run Observation]") %>' />
                        </td>
                    </tr>
                </SelectedItemTemplate>
            </asp:ListView>
            <asp:SqlDataSource ID="PrevObs" runat="server" ConnectionString="<%$ ConnectionStrings:CIConnection1 %>" SelectCommand="SELECT D.[RunObservation] AS [Previous Run Observation] FROM [PMS1].[dbo].[SPCSummary] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPCRunObservations] R WITH(NOLOCK) ON S.[ExperimentId] = R.[ExperimentId] LEFT JOIN [PMS1].[dbo].[SPC_DL_RunObservations] D WITH(NOLOCK) ON R.[RunObservation] = D.[ID] WHERE (S.[PouchSerialNumber] = @PouchSerialNumber)">
                <SelectParameters>
                    <asp:ControlParameter ControlID="ComboBox1" Name="PouchSerialNumber" PropertyName="SelectedValue" />
                </SelectParameters>
            </asp:SqlDataSource>
        </div>
        <div id="RunOb" class="auto-style3">
            <asp:Label ID="runob1lab" runat="server" Text="Run Observation 1" Visible="True"></asp:Label>&nbsp;&nbsp;&nbsp;<asp:DropDownList ID="DropDownList1" runat="server" DataSourceID="SqlDataSource2" DataTextField="RunObservation" DataValueField="Id">
            </asp:DropDownList>
            <br />
            <asp:Button ID="add1" runat="server" OnClick="Button4_Click" Text="+" />&nbsp;&nbsp;
            <asp:Label ID="runob2lab" runat="server" Text="Run Observation 2" Visible="False"></asp:Label>&nbsp;&nbsp;&nbsp;
            <asp:DropDownList ID="DropDownList3" runat="server" DataSourceID="SqlDataSource2" DataTextField="RunObservation" DataValueField="Id" Visible="False">
            </asp:DropDownList>
            &nbsp;&nbsp;
            <asp:Button ID="del1" runat="server" OnClick="del1_Click" Text="x" Visible="False" />
            <br />
            <asp:Button ID="add2" runat="server" OnClick="Button5_Click" Text="+" Visible="False" />&nbsp;&nbsp;
            <asp:Label ID="runob3lab" runat="server" Text="Run Observation 3" Visible="False"></asp:Label>&nbsp;&nbsp;&nbsp;
            <asp:DropDownList ID="DropDownList4" runat="server" DataSourceID="SqlDataSource2" DataTextField="RunObservation" DataValueField="Id" CssClass="auto-style4" Visible="False">
            </asp:DropDownList>
            &nbsp;&nbsp;
            <asp:Button ID="del2" runat="server" OnClick="del2_Click" Text="x" Visible="False" />
            <br />
            <asp:Button ID="add3" runat="server" OnClick="Button6_Click" Text="+" Visible="False"/>&nbsp;&nbsp;
            <asp:Label ID="runob4lab" runat="server" Text="Run Observation 4" Visible="False"></asp:Label>&nbsp;&nbsp;&nbsp;
            <asp:DropDownList ID="DropDownList5" runat="server" DataSourceID="SqlDataSource2" DataTextField="RunObservation" DataValueField="Id" CssClass="auto-style4" Visible="False">
            </asp:DropDownList>
            &nbsp;&nbsp;
            <asp:Button ID="del3" runat="server" OnClick="del3_Click" Text="x" Visible="False" />
            <br />
            <asp:Button ID="add4" runat="server" OnClick="Button7_Click" Text="+" Visible="False"/>&nbsp;&nbsp;
            <asp:Label ID="runob5lab" runat="server" Text="Run Observation 5" Visible="False"></asp:Label>&nbsp;&nbsp;&nbsp;
            <asp:DropDownList ID="DropDownList6" runat="server" DataSourceID="SqlDataSource2" DataTextField="RunObservation" DataValueField="Id" CssClass="auto-style4" Visible="False">
            </asp:DropDownList>
            &nbsp;&nbsp;
            <asp:Button ID="del4" runat="server" OnClick="del4_Click" Text="x" Visible="False" />
            <br />
            <asp:SqlDataSource ID="SqlDataSource2" runat="server" ConnectionString="<%$ ConnectionStrings:CIConnection1 %>" SelectCommand="SELECT * FROM [SPC_DL_RunObservations]"></asp:SqlDataSource>
            <asp:Label ID="Label1" runat="server" Text="Previous Run Observation" Visible="False"></asp:Label>&nbsp;&nbsp;&nbsp;<asp:DropDownList ID="DropDownList7" runat="server" DataSourceID="PrevObsId" DataTextField="RunObservation" DataValueField="Id" Visible="False">
            </asp:DropDownList>
            <br />
            <asp:Label ID="Label2" runat="server" Text="Update to" Visible="False"></asp:Label>&nbsp;&nbsp;&nbsp;<asp:DropDownList ID="DropDownList8" runat="server" DataSourceID="SqlDataSource2" DataTextField="RunObservation" DataValueField="Id" Visible="False">
            </asp:DropDownList>
            <br />
            <asp:SqlDataSource ID="PrevObsId" runat="server" ConnectionString="<%$ ConnectionStrings:CIConnection1 %>" SelectCommand="SELECT R.[RunObservation] AS [Id], D.[RunObservation] FROM [PMS1].[dbo].[SPCSummary] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPCRunObservations] R WITH(NOLOCK) ON S.[ExperimentId] = R.[ExperimentId] LEFT JOIN [PMS1].[dbo].[SPC_DL_RunObservations] D WITH(NOLOCK) ON R.[RunObservation] = D.[ID] WHERE (S.[PouchSerialNumber] = @PouchSerialNumber)">
                <SelectParameters>
                    <asp:ControlParameter ControlID="ComboBox1" Name="PouchSerialNumber" PropertyName="SelectedValue" />
                </SelectParameters>
            </asp:SqlDataSource>
            <br />
            <asp:Button ID="Button1" runat="server" Text="Add New Observation" Width="200px" OnClick="Button1_Click" Visible="False" BackColor="#CCCCCC" />

            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <asp:Button ID="updatebut" runat="server" OnClick="updatebut_Click" Text="Update Previous Observation" Visible="False" />
            <br />
            <br />
            <asp:Button ID="Button4" runat="server" OnClick="Button4_Click1" Text="Submit Observation" />
            <br />
            <asp:Label ID="submitLabel" runat="server" ForeColor="Blue"></asp:Label>

        </div>
    </form>
</body>
</html>
