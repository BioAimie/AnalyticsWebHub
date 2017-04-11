using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.SqlClient;
using System.Configuration;
using System.Data;

namespace PSPC
{
    public partial class Curator : System.Web.UI.Page
    {
        SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["CIConnection"].ConnectionString);

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                SqlDataAdapter da = new SqlDataAdapter("SELECT DISTINCT S.[PouchSerialNumber] FROM[PMS1].[dbo].[SPC2014] S WITH(NOLOCK) LEFT JOIN[PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK) ON S.[ExperimentId] = R.[ExperimentId] WHERE[RunObservations] IS NULL AND[StartTime] IS NOT NULL AND[SampleId] NOT LIKE '%Alpha%' AND [SampleId] NOT LIKE '%Beta%' AND[SampleId] NOT LIKE '%Gamma%' ORDER BY S.[PouchSerialNumber] DESC", con);
                DataTable dt = new DataTable();
                da.Fill(dt);
                ComboBox1.DataSource = dt;
                ComboBox1.DataTextField = "PouchSerialNumber";
                DataBind();
                PrevRunOb.Visible = false;
            }
        }

        protected void Button3_Click(object sender, EventArgs e)
        {
            SqlDataAdapter da = new SqlDataAdapter("SELECT DISTINCT S.[PouchSerialNumber] FROM[PMS1].[dbo].[SPC2014] S WITH(NOLOCK) LEFT JOIN[PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK) ON S.[ExperimentId] = R.[ExperimentId] WHERE[RunObservations] IS NULL AND[StartTime] IS NOT NULL AND[SampleId] NOT LIKE '%Alpha%' AND [SampleId] NOT LIKE '%Beta%' AND[SampleId] NOT LIKE '%Gamma%' ORDER BY S.[PouchSerialNumber] DESC", con);
            DataTable dt = new DataTable();
            da.Fill(dt);
            ComboBox1.DataSource = dt;
            ComboBox1.DataTextField = "PouchSerialNumber";
            DataBind();
            PrevRunOb.Visible = false;
            submitLabel.Visible = false;
            updatebut.Visible = false;
            Button1.Visible = false;
            runob2lab.Visible = false;
            DropDownList3.Visible = false;
            add2.Visible = false;
            del1.Visible = false;
            runob3lab.Visible = false;
            DropDownList4.Visible = false;
            add3.Visible = false;
            del2.Visible = false;
            runob4lab.Visible = false;
            DropDownList5.Visible = false;
            add4.Visible = false;
            del3.Visible = false;
            runob5lab.Visible = false;
            DropDownList6.Visible = false;
            del4.Visible = false;
            runob1lab.Visible = true;
            DropDownList1.Visible = true;
            add1.Visible = true;
            Label1.Visible = false;
            Label2.Visible = false;
            DropDownList7.Visible = false;
            DropDownList8.Visible = false;
        }

        protected void Button2_Click(object sender, EventArgs e)
        {
            SqlDataAdapter da = new SqlDataAdapter("SELECT DISTINCT S.[PouchSerialNumber] FROM [PMS1].[dbo].[SPC2014] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK) ON S.[ExperimentId] = R.[ExperimentId] LEFT JOIN[PMS1].[dbo].[SPC2014_DL_RunObservation] D WITH(NOLOCK) ON R.[RunObservations] = D.[ID] WHERE R.[RunObservations] IS NOT NULL AND[StartTime] IS NOT NULL AND[SampleId] NOT LIKE '%Alpha%' AND[SampleId] NOT LIKE '%Beta%' AND[SampleId] NOT LIKE '%Gamma%' ORDER BY S.[PouchSerialNumber] DESC", con);
            DataTable dt = new DataTable();
            da.Fill(dt);
            ComboBox1.DataSource = dt;
            ComboBox1.DataTextField = "PouchSerialNumber";
            DataBind();
            PrevRunOb.Visible = true;
            submitLabel.Visible = false;
            updatebut.Visible = true;
            Button1.Visible = true;
            runob2lab.Visible = false;
            DropDownList3.Visible = false;
            add2.Visible = false;
            del1.Visible = false;
            runob3lab.Visible = false;
            DropDownList4.Visible = false;
            add3.Visible = false;
            del2.Visible = false;
            runob4lab.Visible = false;
            DropDownList5.Visible = false;
            add4.Visible = false;
            del3.Visible = false;
            runob5lab.Visible = false;
            DropDownList6.Visible = false;
            del4.Visible = false;
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            runob1lab.Visible = true;
            DropDownList1.Visible = true;
            add1.Visible = true;
            Label1.Visible = false;
            Label2.Visible = false;
            DropDownList7.Visible = false;
            DropDownList8.Visible = false;
        }

        protected void Button4_Click(object sender, EventArgs e)
        {
            runob2lab.Visible = true;
            DropDownList3.Visible = true;
            add2.Visible = true;
            del1.Visible = true;
        }

        protected void Button5_Click(object sender, EventArgs e)
        {
            runob3lab.Visible = true;
            DropDownList4.Visible = true;
            add3.Visible = true;
            del2.Visible = true;
        }

        protected void Button6_Click(object sender, EventArgs e)
        {
            runob4lab.Visible = true;
            DropDownList5.Visible = true;
            add4.Visible = true;
            del3.Visible = true;
        }

        protected void Button7_Click(object sender, EventArgs e)
        {
            runob5lab.Visible = true;
            DropDownList6.Visible = true;
            del4.Visible = true;
        }

        protected void del1_Click(object sender, EventArgs e)
        {
            runob2lab.Visible = false;
            DropDownList3.Visible = false;
            add2.Visible = false;
            del1.Visible = false;
        }

        protected void del2_Click(object sender, EventArgs e)
        {
            runob3lab.Visible = false;
            DropDownList4.Visible = false;
            add3.Visible = false;
            del2.Visible = false;
        }

        protected void del3_Click(object sender, EventArgs e)
        {
            runob4lab.Visible = false;
            DropDownList5.Visible = false;
            add4.Visible = false;
            del3.Visible = false;
        }

        protected void del4_Click(object sender, EventArgs e)
        {
            runob5lab.Visible = false;
            DropDownList6.Visible = false;
            del4.Visible = false;
        }

        protected void updatebut_Click(object sender, EventArgs e)
        {
            runob2lab.Visible = false;
            DropDownList3.Visible = false;
            add2.Visible = false;
            del1.Visible = false;
            runob3lab.Visible = false;
            DropDownList4.Visible = false;
            add3.Visible = false;
            del2.Visible = false;
            runob4lab.Visible = false;
            DropDownList5.Visible = false;
            add4.Visible = false;
            del3.Visible = false;
            runob5lab.Visible = false;
            DropDownList6.Visible = false;
            del4.Visible = false;
            runob1lab.Visible = false;
            DropDownList1.Visible = false;
            add1.Visible = false;
            Label1.Visible = true;
            Label2.Visible = true;
            DropDownList7.Visible = true;
            DropDownList8.Visible = true;
        }

        protected void Button4_Click1(object sender, EventArgs e)
        {
            if (DropDownList8.Visible == false)
            {
                SqlCommand cmd = new SqlCommand("PSPCUpdateRunObservations", con);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("PouchSerialNumber", ComboBox1.Text);
                cmd.Parameters.AddWithValue("RunObservations", DropDownList1.SelectedValue);
                cmd.Parameters.AddWithValue("ExperimentID", ExpID.Text);
                cmd.Parameters.AddWithValue("Status", "New");
                con.Open();
                cmd.ExecuteNonQuery();
                con.Close();
                if (runob2lab.Visible == true)
                {
                    cmd.Parameters["RunObservations"].Value = DropDownList3.SelectedValue;
                    con.Open();
                    cmd.ExecuteNonQuery();
                    con.Close();
                }
                if (runob3lab.Visible == true)
                {
                    cmd.Parameters["RunObservations"].Value = DropDownList4.SelectedValue;
                    con.Open();
                    cmd.ExecuteNonQuery();
                    con.Close();
                }
                if (runob4lab.Visible == true)
                {
                    cmd.Parameters["RunObservations"].Value = DropDownList5.SelectedValue;
                    con.Open();
                    cmd.ExecuteNonQuery();
                    con.Close();
                }
                if (runob5lab.Visible == true)
                {
                    cmd.Parameters["RunObservations"].Value = DropDownList6.SelectedValue;
                    con.Open();
                    cmd.ExecuteNonQuery();
                    con.Close();
                }
                submitLabel.Text = "The run observation has been recorded.";
                submitLabel.Visible = true;
            }
            else
            {
                SqlCommand cmd = new SqlCommand("PSPCUpdateRunObservations", con);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("PouchSerialNumber", ComboBox1.Text);
                cmd.Parameters.AddWithValue("PrevRunObservation", DropDownList7.SelectedValue);
                cmd.Parameters.AddWithValue("RunObservations", DropDownList8.SelectedValue);
                cmd.Parameters.AddWithValue("ExperimentID", ExpID.Text);
                cmd.Parameters.AddWithValue("Status", "Update");
                con.Open();
                cmd.ExecuteNonQuery();
                con.Close();
                submitLabel.Text = "The run observation has been recorded.";
                submitLabel.Visible = true;
            }
        }

        protected void ComboBox1_SelectedIndexChanged(object sender, EventArgs e)
        {
            SqlDataAdapter da = new SqlDataAdapter("SELECT * FROM [PMS1].[dbo].[SPC2014] S WITH(NOLOCK) LEFT JOIN [PMS1].[dbo].[SPC2014RunObservations] R WITH(NOLOCK) ON S.[ExperimentId] = R.[ExperimentId] LEFT JOIN [PMS1].[dbo].[SPC2014_DL_RunObservation] D WITH(NOLOCK) ON R.[RunObservations] = D.[ID] WHERE S.[PouchSerialNumber] LIKE'" + ComboBox1.Text + "'", con);
            DataTable dt = new DataTable();
            da.Fill(dt);
            PanelVersion.Text = dt.Rows[0][7].ToString();
            PouchLot.Text = dt.Rows[0][1].ToString();
            Instrument.Text = dt.Rows[0][8].ToString();
            StartTime.Text = dt.Rows[0][0].ToString();
            SampleID.Text = dt.Rows[0][3].ToString();
            PouchCode.Text = dt.Rows[0][11].ToString();
            ExpID.Text = dt.Rows[0][10].ToString();
            submitLabel.Visible = false;
            runob2lab.Visible = false;
            DropDownList3.Visible = false;
            add2.Visible = false;
            del1.Visible = false;
            runob3lab.Visible = false;
            DropDownList4.Visible = false;
            add3.Visible = false;
            del2.Visible = false;
            runob4lab.Visible = false;
            DropDownList5.Visible = false;
            add4.Visible = false;
            del3.Visible = false;
            runob5lab.Visible = false;
            DropDownList6.Visible = false;
            del4.Visible = false;
        }

        protected void Button5Link_Click(object sender, EventArgs e)
        {
            Response.Redirect("http://10.1.23.96:3030");
        }
    }
}