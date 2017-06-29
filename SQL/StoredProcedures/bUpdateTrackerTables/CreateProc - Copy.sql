USE PMS1
GO

IF OBJECT_ID('[dbo].[bUpdateTrackerTables]') IS NOT NULL
DROP PROCEDURE [dbo].[bUpdateTrackerTables]
GO

CREATE PROCEDURE [dbo].[bUpdateTrackerTables]
AS
BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[Complaint] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[Complaint];
WITH [Props] ([TicketId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT 
    BT.[TicketId],
    P.[PropertyId], 
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT 
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
),
[UserProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DateTimeProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[TitleProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ShortTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[LongTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[CheckboxProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], CAST(T.[RecordedValue] AS SMALLINT)
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
        ),
[YesNoNAProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DropdownProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ProblemDescriptionProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ProblemDescriptionProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      )
INSERT INTO [dbo].[Complaint]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=56) AS [AssignedTo],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=53) AS [BecameAwareDate],
  (SELECT MAX([RecordedValue]) FROM [TitleProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=32) AS [ComplaintTitle],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=38) AS [ContactEmail],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=37) AS [ContactFaxNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=36) AS [ContactTelephoneNumber],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=39) AS [CustomerAddress],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=35) AS [CustomerContact],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=33) AS [CustomerId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=34) AS [CustomerName],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=202) AS [ExternalComplaintNotificationReferenceNumber],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=60) AS [Investigation],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=54) AS [IssueCI],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=50) AS [IVDProduct],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=61) AS [JustificationforComplaintEscalation],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=52) AS [PatientCareAffected],
  (SELECT MAX([RecordedValue]) FROM [ProblemDescriptionProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=45) AS [ProblemDescription],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=40) AS [ProductType],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=239) AS [Region],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=55) AS [RelatedCI],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=201) AS [Territory]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  WHERE BT.[Tracker] = 'Complaint' AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT
BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[NCR] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[NCR];
WITH [Props] ([TicketId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT 
    BT.[TicketId],
    P.[PropertyId], 
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT 
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
),
[LongTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[UserProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[MoneyProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[MoneyProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ApproverUserProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ApproverUserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DateTimeProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ShortTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[YesNoNAProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[TitleProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DropdownProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ProblemDescriptionProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ProblemDescriptionProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      )
INSERT INTO [dbo].[NCR]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=190) AS [Assignedfor],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=9) AS [AssignedTo],
  (SELECT MAX([RecordedValue]) FROM [MoneyProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=67) AS [Costofscrap],
  (SELECT MAX([RecordedValue]) FROM [ApproverUserProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=25) AS [DispositionApprover],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=198) AS [DispositionCompletedDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=10) AS [Investigation],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=197) AS [InvestigationCompletedDate],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=204) AS [ManufacturerLotNumber],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=31) AS [MDRInvestigation],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=30) AS [MDRRequired],
  (SELECT MAX([RecordedValue]) FROM [TitleProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=3) AS [NCRTitle],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=4) AS [NCRType],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=12) AS [ProblemArea],
  (SELECT MAX([RecordedValue]) FROM [ProblemDescriptionProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=5) AS [ProblemDescription],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=8) AS [RecommendedDisposition],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=26) AS [RelatedCAPA],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=29) AS [RiskAssessment],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=65) AS [SupplierCorrectiveActionRequest],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=27) AS [Supplierresponsibilityidentified],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=66) AS [WhereFound]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  WHERE BT.[Tracker] = 'NCR' AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT
BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMA] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMA];
WITH [Props] ([TicketId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT 
    BT.[TicketId],
    P.[PropertyId], 
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT 
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
),
[DropdownProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ShortTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DateTimeProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[LongTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DecimalProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[CheckboxProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], CAST(T.[RecordedValue] AS SMALLINT)
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
        ),
[IntegerProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[TitleProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[SummedServiceHourProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[SummedServiceHourProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      )
INSERT INTO [dbo].[RMA]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=146) AS [AssignedServiceCenter],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=82) AS [ComplaintNumber],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=140) AS [CreditMemoIssueDate],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=139) AS [CreditMemoNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=69) AS [CustomerId],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=144) AS [CustomerNotification],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=172) AS [Deconperformed],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=128) AS [HoursOn],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=129) AS [HoursRun],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=205) AS [LoanerRMACompleted],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=81) AS [MASRMANumber],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=143) AS [NotifyDate],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=187) AS [PartDisposition],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=126) AS [PotentiallyReportableEventIdentified],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=84) AS [PreliminaryActions],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=169) AS [PrepaidTrackingNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=184) AS [Priority],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=87) AS [ProductLine],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=171) AS [QuarantineCompletionDate],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=147) AS [QuarantineReleaseDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=83) AS [ReasonforReturn],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=100) AS [ReceivedDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=208) AS [ReceivingIssueDescription],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=240) AS [Region],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=127) AS [RelatedReportableEventComplaintInvestigation],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=86) AS [ReturnShippingAddress],
  (SELECT MAX([RecordedValue]) FROM [TitleProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=68) AS [RMATitle],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=160) AS [RMAType],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=137) AS [SalesOrderNumber],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=131) AS [ServiceCompleted],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=183) AS [ServiceTier],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=142) AS [ShippingDate],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=138) AS [SODate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=85) AS [SpecialInstructions],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=207) AS [SystemFailure],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=132) AS [Tier],
  (SELECT MAX([RecordedValue]) FROM [SummedServiceHourProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=130) AS [TotalServiceHours],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=141) AS [TrackingNumber]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  WHERE BT.[Tracker] = 'RMA' AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT
BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[ComplaintAffectedAssays] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[ComplaintAffectedAssays];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[ComplaintAffectedAssays]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=151) AS [AffectedAssay],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=150) AS [PouchSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=152) AS [RunFileObservation]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=23 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[ComplaintBFDXPartNumber] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[ComplaintBFDXPartNumber];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[ComplaintBFDXPartNumber]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=43) AS [FailureMode],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=42) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=41) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=145) AS [ProductLine],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=44) AS [QuantityAffected],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=186) AS [UDIInformation]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=8 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[ComplaintPRE] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[ComplaintPRE];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[ComplaintPRE]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=51) AS [Criteria]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=11 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[ComplaintRelatedRMAs] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[ComplaintRelatedRMAs];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[ComplaintRelatedRMAs]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=210) AS [AssignedServiceCenter],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=47) AS [Description],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=213) AS [Disposition],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=211) AS [LotSN],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=46) AS [RMA],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=212) AS [WarrantyType]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=9 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[ComplaintRelatedSalesOrders] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[ComplaintRelatedSalesOrders];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[ComplaintRelatedSalesOrders]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=49) AS [Description],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=48) AS [SalesOrder]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=10 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[ComplaintResolutionStepsorCommunications] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[ComplaintResolutionStepsorCommunications];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[ComplaintResolutionStepsorCommunications]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=58) AS [CustomerSupportRepresentative],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=59) AS [DateofAction],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=57) AS [ResolutionSteporCommunication]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=12 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[NCRFailureDetails] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[NCRFailureDetails];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[NCRFailureDetails]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=189) AS [ExplainifOther],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=161) AS [FailureCategory],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=162) AS [SubfailureCategory]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=25 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[NCRPartNumbers] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[NCRPartNumbers];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[PartNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[PartNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[NCRPartNumbers]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [PartNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=1) AS [ComponentPartNumber],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=2) AS [LotorSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=64) AS [PartDescription],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=63) AS [Quantity]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=1 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[NCRPartsAffected] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[NCRPartsAffected];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[NCRPartsAffected]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=16) AS [Disposition],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=18) AS [Explanationifother],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=62) AS [LotorSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=13) AS [PartAffected],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=14) AS [QuantityAffected],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=15) AS [UnitOfMeasure],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=17) AS [UseasisJustification]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=4 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[NCRPONumbers] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[NCRPONumbers];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[NCRPONumbers]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=6) AS [PONumber]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=2 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[NCRVendors] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[NCRVendors];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[NCRVendors]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=7) AS [Vendor]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=3 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAActionsPerformed] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAActionsPerformed];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DecimalProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAActionsPerformed]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=188) AS [ActionsCompleted],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=117) AS [ActionsPerformed],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=119) AS [ServiceHours],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=118) AS [ServicedBy]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=19 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAInventoryPartsReceived] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAInventoryPartsReceived];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAInventoryPartsReceived]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=180) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=179) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=181) AS [Quantity]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=27 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAInvestigation] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAInvestigation];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAInvestigation]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=112) AS [Date],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=113) AS [InvestigationResults],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=111) AS [InvestigationTech]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=17 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAPartInformation] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAPartInformation];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[YesNoNAProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAPartInformation]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=77) AS [Disposition],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=80) AS [EarlyFailureType],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=79) AS [LoanerNeeded],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=72) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=71) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=70) AS [ProductType],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=73) AS [Quantity],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=78) AS [RefundorCredit],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=74) AS [RepairRequested],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=75) AS [Replacement],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=185) AS [UDIInformation],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=76) AS [WarrantyType]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=13 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAPartsUsed] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAPartsUsed];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[PartNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[PartNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAPartsUsed]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=115) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=159) AS [PartDescription],
  (SELECT MAX([RecordedValue]) FROM [PartNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=114) AS [PartUsed],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=116) AS [Quantity],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=158) AS [UnitOfMeasure]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=18 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAQCCheck] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAQCCheck];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DecimalProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAQCCheck]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=136) AS [DHRComplete],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=134) AS [QCDate],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=135) AS [QCHours],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=133) AS [QCTech],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=209) AS [ReasonCode]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=22 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMARelatedRMAs] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMARelatedRMAs];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMARelatedRMAs]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=156) AS [Description],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=155) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=154) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=153) AS [RMANumber]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=24 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAPartsReceived] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAPartsReceived];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[YesNoNAProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAPartsReceived]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=177) AS [DeconLabelPresent],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=174) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=173) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=175) AS [Quantity],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=176) AS [ReceivedBy]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=26 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAWorkflow] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAWorkflow];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[CheckboxProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], CAST(T.[RecordedValue] AS SMALLINT)
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAWorkflow]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=94) AS [Accounting],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=89) AS [Decontamination],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=196) AS [Dispatch],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=92) AS [InstrumentQCandDHR],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=157) AS [LoanerRMA],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=90) AS [NonInstrumentInvestigation],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=148) AS [QuarantineRelease],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=88) AS [Receiving],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=93) AS [SalesOrderGeneration],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=91) AS [Service],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=95) AS [Shipping]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=14 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMARootCauses] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMARootCauses];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMARootCauses]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=124) AS [FailureCategory],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=121) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=123) AS [ProblemArea],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=125) AS [SubFailureCategory],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=122) AS [WhereFound]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=21 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

BEGIN TRAN
SELECT TOP 1 1 FROM [dbo].[RMAServiceCodes] WITH(TABLOCKX, HOLDLOCK);
TRUNCATE TABLE [dbo].[RMAServiceCodes];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
INSERT INTO [dbo].[RMAServiceCodes]
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=120) AS [ServiceCode],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=200) AS [ServiceCodeDescription]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=20 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
COMMIT

GO
-- Perform initial creation of tables, to establish their schemas
BEGIN TRAN
IF OBJECT_ID('[dbo].[Complaint]') IS NOT NULL
  DROP TABLE [dbo].[Complaint];
WITH [Props] ([TicketId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT 
    BT.[TicketId],
    P.[PropertyId], 
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT 
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
),
[UserProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DateTimeProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[TitleProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ShortTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[LongTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[CheckboxProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], CAST(T.[RecordedValue] AS SMALLINT)
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
        ),
[YesNoNAProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DropdownProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ProblemDescriptionProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ProblemDescriptionProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      )
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=56) AS [AssignedTo],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=53) AS [BecameAwareDate],
  (SELECT MAX([RecordedValue]) FROM [TitleProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=32) AS [ComplaintTitle],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=38) AS [ContactEmail],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=37) AS [ContactFaxNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=36) AS [ContactTelephoneNumber],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=39) AS [CustomerAddress],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=35) AS [CustomerContact],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=33) AS [CustomerId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=34) AS [CustomerName],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=202) AS [ExternalComplaintNotificationReferenceNumber],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=60) AS [Investigation],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=54) AS [IssueCI],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=50) AS [IVDProduct],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=61) AS [JustificationforComplaintEscalation],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=52) AS [PatientCareAffected],
  (SELECT MAX([RecordedValue]) FROM [ProblemDescriptionProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=45) AS [ProblemDescription],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=40) AS [ProductType],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=239) AS [Region],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=55) AS [RelatedCI],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=201) AS [Territory]
INTO [dbo].[Complaint]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  WHERE BT.[Tracker] = 'Complaint' AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
ALTER TABLE [dbo].[Complaint] ADD PRIMARY KEY (TicketId);
COMMIT
BEGIN TRAN
IF OBJECT_ID('[dbo].[NCR]') IS NOT NULL
  DROP TABLE [dbo].[NCR];
WITH [Props] ([TicketId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT 
    BT.[TicketId],
    P.[PropertyId], 
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT 
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
),
[LongTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[UserProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[MoneyProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[MoneyProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ApproverUserProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ApproverUserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DateTimeProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ShortTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[YesNoNAProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[TitleProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DropdownProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ProblemDescriptionProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ProblemDescriptionProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      )
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=190) AS [Assignedfor],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=9) AS [AssignedTo],
  (SELECT MAX([RecordedValue]) FROM [MoneyProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=67) AS [Costofscrap],
  (SELECT MAX([RecordedValue]) FROM [ApproverUserProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=25) AS [DispositionApprover],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=198) AS [DispositionCompletedDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=10) AS [Investigation],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=197) AS [InvestigationCompletedDate],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=204) AS [ManufacturerLotNumber],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=31) AS [MDRInvestigation],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=30) AS [MDRRequired],
  (SELECT MAX([RecordedValue]) FROM [TitleProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=3) AS [NCRTitle],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=4) AS [NCRType],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=12) AS [ProblemArea],
  (SELECT MAX([RecordedValue]) FROM [ProblemDescriptionProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=5) AS [ProblemDescription],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=8) AS [RecommendedDisposition],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=26) AS [RelatedCAPA],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=29) AS [RiskAssessment],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=65) AS [SupplierCorrectiveActionRequest],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=27) AS [Supplierresponsibilityidentified],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=66) AS [WhereFound]
INTO [dbo].[NCR]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  WHERE BT.[Tracker] = 'NCR' AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
ALTER TABLE [dbo].[NCR] ADD PRIMARY KEY (TicketId);
COMMIT
BEGIN TRAN
IF OBJECT_ID('[dbo].[RMA]') IS NOT NULL
  DROP TABLE [dbo].[RMA];
WITH [Props] ([TicketId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT 
    BT.[TicketId],
    P.[PropertyId], 
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT 
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketProperties] TP WITH(NOLOCK) ON TP.[GeneralTicketHistoryId] = GTH.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH(NOLOCK) ON P.[PropertyId] = TP.[PropertyId]
),
[DropdownProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[ShortTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DateTimeProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[LongTextProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[DecimalProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[CheckboxProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], CAST(T.[RecordedValue] AS SMALLINT)
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
        ),
[IntegerProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[TitleProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TitleProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      ),
[SummedServiceHourProperties] ([TicketId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[TicketId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[SummedServiceHourProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
      )
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=146) AS [AssignedServiceCenter],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=82) AS [ComplaintNumber],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=140) AS [CreditMemoIssueDate],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=139) AS [CreditMemoNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=69) AS [CustomerId],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=144) AS [CustomerNotification],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=172) AS [Deconperformed],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=128) AS [HoursOn],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=129) AS [HoursRun],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=205) AS [LoanerRMACompleted],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=81) AS [MASRMANumber],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=143) AS [NotifyDate],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=187) AS [PartDisposition],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=126) AS [PotentiallyReportableEventIdentified],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=84) AS [PreliminaryActions],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=169) AS [PrepaidTrackingNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=184) AS [Priority],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=87) AS [ProductLine],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=171) AS [QuarantineCompletionDate],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=147) AS [QuarantineReleaseDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=83) AS [ReasonforReturn],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=100) AS [ReceivedDate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=208) AS [ReceivingIssueDescription],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=240) AS [Region],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=127) AS [RelatedReportableEventComplaintInvestigation],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=86) AS [ReturnShippingAddress],
  (SELECT MAX([RecordedValue]) FROM [TitleProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=68) AS [RMATitle],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=160) AS [RMAType],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=137) AS [SalesOrderNumber],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=131) AS [ServiceCompleted],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=183) AS [ServiceTier],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=142) AS [ShippingDate],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=138) AS [SODate],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=85) AS [SpecialInstructions],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=207) AS [SystemFailure],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=132) AS [Tier],
  (SELECT MAX([RecordedValue]) FROM [SummedServiceHourProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=130) AS [TotalServiceHours],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[TicketId] = BT.[TicketId] AND T.[TrackablePropertyId]=141) AS [TrackingNumber]
INTO [dbo].[RMA]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  WHERE BT.[Tracker] = 'RMA' AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
ALTER TABLE [dbo].[RMA] ADD PRIMARY KEY (TicketId);
COMMIT
BEGIN TRAN
IF OBJECT_ID('[dbo].[ComplaintAffectedAssays]') IS NOT NULL
DROP TABLE [dbo].[ComplaintAffectedAssays];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=151) AS [AffectedAssay],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=150) AS [PouchSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=152) AS [RunFileObservation]
INTO [dbo].[ComplaintAffectedAssays]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=23 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[ComplaintAffectedAssays]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[ComplaintAffectedAssays]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[ComplaintAffectedAssays]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[ComplaintAffectedAssays]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[ComplaintBFDXPartNumber]') IS NOT NULL
DROP TABLE [dbo].[ComplaintBFDXPartNumber];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=43) AS [FailureMode],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=42) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=41) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=145) AS [ProductLine],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=44) AS [QuantityAffected],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=186) AS [UDIInformation]
INTO [dbo].[ComplaintBFDXPartNumber]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=8 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[ComplaintBFDXPartNumber]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[ComplaintBFDXPartNumber]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[ComplaintBFDXPartNumber]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[ComplaintBFDXPartNumber]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[ComplaintPRE]') IS NOT NULL
DROP TABLE [dbo].[ComplaintPRE];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=51) AS [Criteria]
INTO [dbo].[ComplaintPRE]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=11 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[ComplaintPRE]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[ComplaintPRE]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[ComplaintPRE]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[ComplaintPRE]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[ComplaintRelatedRMAs]') IS NOT NULL
DROP TABLE [dbo].[ComplaintRelatedRMAs];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=210) AS [AssignedServiceCenter],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=47) AS [Description],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=213) AS [Disposition],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=211) AS [LotSN],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=46) AS [RMA],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=212) AS [WarrantyType]
INTO [dbo].[ComplaintRelatedRMAs]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=9 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[ComplaintRelatedRMAs]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[ComplaintRelatedRMAs]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[ComplaintRelatedRMAs]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[ComplaintRelatedRMAs]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[ComplaintRelatedSalesOrders]') IS NOT NULL
DROP TABLE [dbo].[ComplaintRelatedSalesOrders];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=49) AS [Description],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=48) AS [SalesOrder]
INTO [dbo].[ComplaintRelatedSalesOrders]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=10 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[ComplaintRelatedSalesOrders]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[ComplaintRelatedSalesOrders]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[ComplaintRelatedSalesOrders]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[ComplaintRelatedSalesOrders]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[ComplaintResolutionStepsorCommunications]') IS NOT NULL
DROP TABLE [dbo].[ComplaintResolutionStepsorCommunications];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=58) AS [CustomerSupportRepresentative],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=59) AS [DateofAction],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=57) AS [ResolutionSteporCommunication]
INTO [dbo].[ComplaintResolutionStepsorCommunications]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'COMPLAINT' AND O.[TrackableObjectId]=12 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[ComplaintResolutionStepsorCommunications]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[ComplaintResolutionStepsorCommunications]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[ComplaintResolutionStepsorCommunications]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[ComplaintResolutionStepsorCommunications]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[NCRFailureDetails]') IS NOT NULL
DROP TABLE [dbo].[NCRFailureDetails];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=189) AS [ExplainifOther],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=161) AS [FailureCategory],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=162) AS [SubfailureCategory]
INTO [dbo].[NCRFailureDetails]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=25 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[NCRFailureDetails]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[NCRFailureDetails]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[NCRFailureDetails]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[NCRFailureDetails]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[NCRPartNumbers]') IS NOT NULL
DROP TABLE [dbo].[NCRPartNumbers];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[PartNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[PartNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [PartNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=1) AS [ComponentPartNumber],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=2) AS [LotorSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=64) AS [PartDescription],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=63) AS [Quantity]
INTO [dbo].[NCRPartNumbers]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=1 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[NCRPartNumbers]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[NCRPartNumbers]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[NCRPartNumbers]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[NCRPartNumbers]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[NCRPartsAffected]') IS NOT NULL
DROP TABLE [dbo].[NCRPartsAffected];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=16) AS [Disposition],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=18) AS [Explanationifother],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=62) AS [LotorSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=13) AS [PartAffected],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=14) AS [QuantityAffected],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=15) AS [UnitOfMeasure],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=17) AS [UseasisJustification]
INTO [dbo].[NCRPartsAffected]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=4 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[NCRPartsAffected]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[NCRPartsAffected]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[NCRPartsAffected]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[NCRPartsAffected]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[NCRPONumbers]') IS NOT NULL
DROP TABLE [dbo].[NCRPONumbers];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=6) AS [PONumber]
INTO [dbo].[NCRPONumbers]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=2 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[NCRPONumbers]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[NCRPONumbers]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[NCRPONumbers]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[NCRPONumbers]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[NCRVendors]') IS NOT NULL
DROP TABLE [dbo].[NCRVendors];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=7) AS [Vendor]
INTO [dbo].[NCRVendors]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'NCR' AND O.[TrackableObjectId]=3 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[NCRVendors]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[NCRVendors]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[NCRVendors]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[NCRVendors]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAActionsPerformed]') IS NOT NULL
DROP TABLE [dbo].[RMAActionsPerformed];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DecimalProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=188) AS [ActionsCompleted],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=117) AS [ActionsPerformed],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=119) AS [ServiceHours],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=118) AS [ServicedBy]
INTO [dbo].[RMAActionsPerformed]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=19 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAActionsPerformed]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAActionsPerformed]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAActionsPerformed]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAActionsPerformed]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAInventoryPartsReceived]') IS NOT NULL
DROP TABLE [dbo].[RMAInventoryPartsReceived];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=180) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=179) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=181) AS [Quantity]
INTO [dbo].[RMAInventoryPartsReceived]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=27 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAInventoryPartsReceived]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAInventoryPartsReceived]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAInventoryPartsReceived]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAInventoryPartsReceived]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAInvestigation]') IS NOT NULL
DROP TABLE [dbo].[RMAInvestigation];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LongTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LongTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=112) AS [Date],
  (SELECT MAX([RecordedValue]) FROM [LongTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=113) AS [InvestigationResults],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=111) AS [InvestigationTech]
INTO [dbo].[RMAInvestigation]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=17 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAInvestigation]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAInvestigation]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAInvestigation]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAInvestigation]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAPartInformation]') IS NOT NULL
DROP TABLE [dbo].[RMAPartInformation];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[YesNoNAProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=77) AS [Disposition],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=80) AS [EarlyFailureType],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=79) AS [LoanerNeeded],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=72) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=71) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=70) AS [ProductType],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=73) AS [Quantity],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=78) AS [RefundorCredit],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=74) AS [RepairRequested],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=75) AS [Replacement],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=185) AS [UDIInformation],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=76) AS [WarrantyType]
INTO [dbo].[RMAPartInformation]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=13 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAPartInformation]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAPartInformation]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAPartInformation]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAPartInformation]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAPartsUsed]') IS NOT NULL
DROP TABLE [dbo].[RMAPartsUsed];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[PartNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[PartNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=115) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=159) AS [PartDescription],
  (SELECT MAX([RecordedValue]) FROM [PartNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=114) AS [PartUsed],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=116) AS [Quantity],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=158) AS [UnitOfMeasure]
INTO [dbo].[RMAPartsUsed]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=18 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAPartsUsed]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAPartsUsed]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAPartsUsed]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAPartsUsed]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAQCCheck]') IS NOT NULL
DROP TABLE [dbo].[RMAQCCheck];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DateTimeProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DateTimeProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[DecimalProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DecimalProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=136) AS [DHRComplete],
  (SELECT MAX([RecordedValue]) FROM [DateTimeProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=134) AS [QCDate],
  (SELECT MAX([RecordedValue]) FROM [DecimalProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=135) AS [QCHours],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=133) AS [QCTech],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=209) AS [ReasonCode]
INTO [dbo].[RMAQCCheck]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=22 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAQCCheck]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAQCCheck]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAQCCheck]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAQCCheck]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMARelatedRMAs]') IS NOT NULL
DROP TABLE [dbo].[RMARelatedRMAs];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=156) AS [Description],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=155) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=154) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=153) AS [RMANumber]
INTO [dbo].[RMARelatedRMAs]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=24 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMARelatedRMAs]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMARelatedRMAs]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMARelatedRMAs]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMARelatedRMAs]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAPartsReceived]') IS NOT NULL
DROP TABLE [dbo].[RMAPartsReceived];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[YesNoNAProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[YesNoNAProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[LotNumberProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[LotNumberProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[UserProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[UserProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [YesNoNAProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=177) AS [DeconLabelPresent],
  (SELECT MAX([RecordedValue]) FROM [LotNumberProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=174) AS [LotSerialNumber],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=173) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=175) AS [Quantity],
  (SELECT MAX([RecordedValue]) FROM [UserProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=176) AS [ReceivedBy]
INTO [dbo].[RMAPartsReceived]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=26 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAPartsReceived]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAPartsReceived]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAPartsReceived]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAPartsReceived]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAWorkflow]') IS NOT NULL
DROP TABLE [dbo].[RMAWorkflow];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[CheckboxProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], CAST(T.[RecordedValue] AS SMALLINT)
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[CheckboxProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=94) AS [Accounting],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=89) AS [Decontamination],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=196) AS [Dispatch],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=92) AS [InstrumentQCandDHR],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=157) AS [LoanerRMA],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=90) AS [NonInstrumentInvestigation],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=148) AS [QuarantineRelease],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=88) AS [Receiving],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=93) AS [SalesOrderGeneration],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=91) AS [Service],
  (SELECT MAX([RecordedValue]) FROM [CheckboxProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=95) AS [Shipping]
INTO [dbo].[RMAWorkflow]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=14 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAWorkflow]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAWorkflow]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAWorkflow]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAWorkflow]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMARootCauses]') IS NOT NULL
DROP TABLE [dbo].[RMARootCauses];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[DropdownProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[DropdownProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=124) AS [FailureCategory],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=121) AS [PartNumber],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=123) AS [ProblemArea],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=125) AS [SubFailureCategory],
  (SELECT MAX([RecordedValue]) FROM [DropdownProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=122) AS [WhereFound]
INTO [dbo].[RMARootCauses]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=21 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMARootCauses]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMARootCauses]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMARootCauses]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMARootCauses]([Status])
COMMIT

BEGIN TRAN
IF OBJECT_ID('[dbo].[RMAServiceCodes]') IS NOT NULL
DROP TABLE [dbo].[RMAServiceCodes];
WITH
[Objects] ([TicketId], [ObjectId], [TrackableObjectId]) AS (
  SELECT
    BT.[TicketId],
    TKO.[ObjectId],
    OB.[TrackableObjectId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketStages] TS WITH(NOLOCK) ON BT.[TicketId] = TS.[TicketId]
  LEFT JOIN 	(
    SELECT
      GTH.[TicketStageId],
      MAX(GTH.[GeneralTicketHistoryId]) AS [GeneralTicketHistoryId]
    FROM [RO_TRACKERS].[Trackers].[dbo].[GeneralTicketHistories] GTH WITH(NOLOCK)
    GROUP BY GTH.[TicketStageId]
  ) GTH ON GTH.[TicketStageId] = TS.[TicketStageId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[TicketObjects] TKO WITH (NOLOCK) ON GTH.[GeneralTicketHistoryId] = TKO.[GeneralTicketHistoryId]
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Objects] OB WITH (NOLOCK) ON OB.[ObjectId] = TKO.[ObjectId]
),
[Props] ([ObjectId], [PropertyId], [TrackablePropertyId]) AS (
  SELECT
    OP.[ObjectId],
    P.[PropertyId],
    P.[TrackablePropertyId]
  FROM [RO_TRACKERS].[Trackers].[dbo].[ObjectProperties] OP WITH (NOLOCK)
  LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[Properties] P WITH (NOLOCK) ON OP.[PropertyId] = P.[PropertyId]
),
[IntegerProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[IntegerProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
),
[ShortTextProperties] ([ObjectId], [PropertyId], [TrackablePropertyId], [RecordedValue]) AS (
  SELECT P.[ObjectId], P.[PropertyId], P.[TrackablePropertyId], T.[RecordedValue]
  FROM [Props] P LEFT JOIN [RO_TRACKERS].[Trackers].[dbo].[ShortTextProperties] T WITH(NOLOCK) ON P.[PropertyId] = T.[PropertyId]
)
SELECT
  BT.[TicketId],
  BT.[CreatedDate],
  BT.[Status],
  BT.[CreatedBy],
  BT.[TicketString],
  BT.[LastModified],
  BT.[InitialCloseDate],
  O.[ObjectId],
  (SELECT MAX([RecordedValue]) FROM [IntegerProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=120) AS [ServiceCode],
  (SELECT MAX([RecordedValue]) FROM [ShortTextProperties] T WHERE T.[ObjectId] = O.[ObjectId] AND T.[TrackablePropertyId]=200) AS [ServiceCodeDescription]
INTO [dbo].[RMAServiceCodes]
FROM [RO_TRACKERS].[Trackers].[dbo].[BaseTicket] BT WITH(NOLOCK)
INNER JOIN [Objects] O ON BT.[TicketId] = O.[TicketId]
WHERE BT.[Tracker] = 'RMA' AND O.[TrackableObjectId]=20 AND BT.[Status] NOT IN ('ClosedVoided','ClosedDuplicate')
CREATE INDEX IDX_TicketId ON [dbo].[RMAServiceCodes]([TicketId])
CREATE INDEX IDX_TicketString ON [dbo].[RMAServiceCodes]([TicketString])
CREATE INDEX IDX_CreatedDate ON [dbo].[RMAServiceCodes]([CreatedDate])
CREATE INDEX IDX_Status ON [dbo].[RMAServiceCodes]([Status])
COMMIT

