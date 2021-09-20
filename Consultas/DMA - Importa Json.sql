CREATE TABLE DMA_Findings
(
 [Databases_ServerName] nvarchar(128)
,[Databases_Name] nvarchar(128)
,[Databases_CompatibilityLevel] nvarchar(128)
,[Databases_SizeMB] decimal (20,2)
,[Databases_Status] nvarchar(128)
,[Databases_ServerVersion] nvarchar(128)
,[AssessmentRecommendations_CompatibilityLevel] nvarchar(128)
,[AssessmentRecommendations_Category] nvarchar(128)
,[AssessmentRecommendations_Severity] nvarchar(128)
,[AssessmentRecommendations_ChangeCategory] nvarchar(128)
,[AssessmentRecommendations_RuleId] nvarchar(128)
,[AssessmentRecommendations_Title] nvarchar(128)
,[AssessmentRecommendations_Impact] nvarchar(4000)
,[AssessmentRecommendations_Recommendation] nvarchar(4000)
,[AssessmentRecommendations_MoreInfo] nvarchar(4000)
,[ImpactedObjects_Name] nvarchar(128)
,[ImpactedObjects_ObjectType] nvarchar(128)
,[ImpactedObjects_ImpactDetail] nvarchar(4000)
,[ImpactedObjects_SuggestedFixes] nvarchar(4000)
);
go
INSERT INTO DMA_Findings( 
 [Databases_ServerName]
,[Databases_Name]
,[Databases_CompatibilityLevel] 
,[Databases_SizeMB]
,[Databases_Status]
,[Databases_ServerVersion] 
,[AssessmentRecommendations_CompatibilityLevel]
,[AssessmentRecommendations_Category]
,[AssessmentRecommendations_Severity]
,[AssessmentRecommendations_ChangeCategory]
,[AssessmentRecommendations_RuleId]
,[AssessmentRecommendations_Title]
,[AssessmentRecommendations_Impact]
,[AssessmentRecommendations_Recommendation]
,[AssessmentRecommendations_MoreInfo]
,[ImpactedObjects_Name]
,[ImpactedObjects_ObjectType]
,[ImpactedObjects_ImpactDetail]
,[ImpactedObjects_SuggestedFixes]
)
SELECT 
 [Databases].[ServerName] AS [Databases_ServerName]
,[Databases].[Name] AS [Databases_Name]
,[Databases].[CompatibilityLevel] AS [Databases_CompatibilityLevel] 
,[Databases].[SizeMB] AS [Databases_SizeMB]
,[Databases].[Status] AS [Databases_Status]
,[Databases].[ServerVersion] AS [Databases_ServerVersion] 
,[AssessmentRecommendations].[CompatibilityLevel] AS [AssessmentRecommendations_CompatibilityLevel]
,[AssessmentRecommendations].[Category] AS [AssessmentRecommendations_Category]
,[AssessmentRecommendations].[Severity] AS [AssessmentRecommendations_Severity]
,[AssessmentRecommendations].[ChangeCategory] AS [AssessmentRecommendations_ChangeCategory]
,[AssessmentRecommendations].[RuleId] AS [AssessmentRecommendations_RuleId]
,[AssessmentRecommendations].[Title] AS [AssessmentRecommendations_Title]
,[AssessmentRecommendations].[Impact] AS [AssessmentRecommendations_Impact]
,[AssessmentRecommendations].[Recommendation] AS [AssessmentRecommendations_Recommendation]
,[AssessmentRecommendations].[MoreInfo] AS [AssessmentRecommendations_MoreInfo]
,[ImpactedObjects].[Name] AS [ImpactedObjects_Name]
,[ImpactedObjects].[ObjectType] AS [ImpactedObjects_ObjectType]
,[ImpactedObjects].[ImpactDetail] AS [ImpactedObjects_ImpactDetail]
,[ImpactedObjects].[SuggestedFixes] AS [ImpactedObjects_SuggestedFixes]
FROM
OPENROWSET(BULK N'D:\SQLServer\DMA\Report_SSMA.json', SINGLE_CLOB) AS json
OUTER APPLY OPENJSON(BulkColumn)
WITH ( 
 [Name] nvarchar(128)
,[Databases] nvarchar(MAX) AS JSON
) AS [Instance]
OUTER APPLY  OPENJSON([Databases])
WITH (
 [ServerName] nvarchar(128)
,[Name] nvarchar(128)
,[CompatibilityLevel] nvarchar(128)
,[SizeMB] decimal (20,2)
,[Status] nvarchar(128)
,[ServerVersion] nvarchar(128)
,[AssessmentRecommendations] nvarchar(MAX) AS JSON
) AS [Databases]
OUTER APPLY OPENJSON([AssessmentRecommendations])
WITH (
 [CompatibilityLevel] nvarchar(128)
,[Category] nvarchar(128)
,[Severity] nvarchar(128)
,[ChangeCategory] nvarchar(128)
,[RuleId] nvarchar(128)
,[Title] nvarchar(128)
,[Impact] nvarchar(4000)
,[Recommendation] nvarchar(4000)
,[MoreInfo] nvarchar(4000)
,[ImpactedObjects] nvarchar(MAX) AS JSON
) AS [AssessmentRecommendations]
OUTER APPLY OPENJSON([ImpactedObjects])
WITH (
 [Name] nvarchar(128)
,[ObjectType] nvarchar(128)
,[ImpactDetail] nvarchar(4000)
,[SuggestedFixes] nvarchar(4000)
) AS [ImpactedObjects];
