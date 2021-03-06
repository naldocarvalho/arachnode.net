/*

You are recommended to back up your database before running this script

Script created by SQL Compare version 8.2.0 from Red Gate Software Ltd at 6/20/2010 2:10:43 PM

*/
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#tmpErrors')) DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
GO
PRINT N'Dropping constraints from [dbo].[CrawlRequests]'
GO
ALTER TABLE [dbo].[CrawlRequests] DROP CONSTRAINT [CK_CrawlRequests_2]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Dropping constraints from [dbo].[CrawlRequests]'
GO
ALTER TABLE [dbo].[CrawlRequests] DROP CONSTRAINT [CK_CrawlRequests_3]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[CrawlRequests]'
GO
ALTER TABLE [dbo].[CrawlRequests] ADD
[RenderType] [tinyint] NOT NULL CONSTRAINT [DF_CrawlRequests_RenderType] DEFAULT ((0)),
[RenderTypeForChildren] [tinyint] NOT NULL CONSTRAINT [DF_CrawlRequests_RenderTypeForChildren] DEFAULT ((0))
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [dbo].[CrawlRequests] ALTER COLUMN [RestrictCrawlTo] [tinyint] NOT NULL
ALTER TABLE [dbo].[CrawlRequests] ALTER COLUMN [RestrictDiscoveriesTo] [tinyint] NOT NULL
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[arachnode_omsp_CrawlRequests_INSERT]'
GO
ALTER PROCEDURE [dbo].[arachnode_omsp_CrawlRequests_INSERT]
    @Created [datetime] ,
    @AbsoluteUri1 [varchar](884) ,
    @AbsoluteUri2 [varchar](884) ,
    @CurrentDepth [int] ,
    @MaximumDepth [int] ,
    @RestrictCrawlTo TINYINT ,
    @RestrictDiscoveriesTo TINYINT ,
    @Priority [float] ,
    @RenderType TINYINT ,
    @RenderTypeForChildren TINYINT ,
    @CrawlRequestID [bigint] OUTPUT
    WITH EXECUTE AS CALLER
AS 
    SET NOCOUNT ON

    IF NOT EXISTS ( SELECT  AbsoluteUri2
                    FROM    dbo.CrawlRequests
                    WHERE   AbsoluteUri2 = @AbsoluteUri2 )
        /*AND NOT EXISTS ( SELECT AbsoluteUri
                         FROM   dbo.Discoveries
                         WHERE  AbsoluteUri = @AbsoluteUri2 ) */
        BEGIN
            INSERT  dbo.CrawlRequests
                    ( Created ,
                      AbsoluteUri1 ,
                      AbsoluteUri2 ,
                      CurrentDepth ,
                      MaximumDepth ,
                      RestrictCrawlTo ,
                      RestrictDiscoveriesTo ,
                      Priority ,
                      RenderType ,
                      RenderTypeForChildren
                    )
            VALUES  ( @Created ,
                      @AbsoluteUri1 ,
                      @AbsoluteUri2 ,
                      @CurrentDepth ,
                      @MaximumDepth,
                      @RestrictCrawlTo ,
                      @RestrictDiscoveriesTo ,
                      @Priority ,
                      @RenderType ,
                      @RenderTypeForChildren
                    )
        END
    ELSE 
        BEGIN
            UPDATE  dbo.CrawlRequests
            SET     Created = @Created ,
                    CurrentDepth = @CurrentDepth ,
                    MaximumDepth = @MAximumDepth ,
                    RestrictCrawlTo = @RestrictCrawlTo ,
                    RestrictDiscoveriesTo = @RestrictDiscoveriesTo ,	
                    Priority = @Priority ,
					RenderType = @RenderType ,
                    RenderTypeForChildren = @RenderTypeForChildren
            WHERE   AbsoluteUri1 = @AbsoluteUri1
                    AND AbsoluteUri2 = @AbsoluteUri2
        END

    SET @CrawlRequestID = ( SELECT  ID
                            FROM    CrawlRequests
                            WHERE   AbsoluteUri1 = @AbsoluteUri1
                                    AND AbsoluteUri2 = @AbsoluteUri2
                          )
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[arachnode_omsp_CrawlRequests_SELECT]'
GO
ALTER PROCEDURE [dbo].[arachnode_omsp_CrawlRequests_SELECT]
    @MaximumNumberOfCrawlRequestsToCreatePerBatch [int] ,
    @CreateCrawlRequestsFromDatabaseCrawlRequests [bit] = 1 ,
    @CreateCrawlRequestsFromDatabaseFiles [bit] = 0 ,
    @AssignCrawlRequestPrioritiesForFiles [bit] = 1 ,
    @CreateCrawlRequestsFromDatabaseHyperLinks [bit] = 0 ,
    @AssignCrawlRequestPrioritiesForHyperLinks [bit] = 1 ,
    @CreateCrawlRequestsFromDatabaseImages [bit] = 0 ,
    @AssignCrawlRequestPrioritiesForImages [bit] = 1 ,
    @CreateCrawlRequestsFromDatabaseWebPages [bit] = 0 ,
    @AssignCrawlRequestPrioritiesForWebPages [bit] = 1
    WITH EXECUTE AS CALLER
AS 
    SET ROWCOUNT @MaximumNumberOfCrawlRequestsToCreatePerBatch

    SELECT TOP ( @MaximumNumberOfCrawlRequestsToCreatePerBatch )
            *
    FROM    ( SELECT TOP ( @MaximumNumberOfCrawlRequestsToCreatePerBatch )
                        Created ,
                        cr.AbsoluteUri1 ,
                        cr.AbsoluteUri2 ,
                        CurrentDepth ,
                        MaximumDepth ,
                        RestrictCrawlTo ,
                        RestrictDiscoveriesTo ,
                        Priority ,
                        RenderType,
                        RenderTypeForChildren,
                        0 AS DiscoveryTypeID
              FROM      CrawlRequests (NOLOCK) AS cr
                        LEFT OUTER JOIN DisallowedAbsoluteUris (NOLOCK) AS dau ON cr.AbsoluteUri2 = dau.AbsoluteUri
              WHERE     @CreateCrawlRequestsFromDatabaseCrawlRequests = 1
						--AND @@ROWCOUNT < @MaximumNumberOfCrawlRequestsToCreatePerBatch
                        AND ( dau.ID IS NULL )
              ORDER BY  Priority DESC ,
                        Created ASC
              UNION
              /**/ --HyperLinks
              SELECT TOP ( @MaximumNumberOfCrawlRequestsToCreatePerBatch )
                        MAX(hld.LastDiscovered) ,
                        hl.AbsoluteUri ,
                        hl.AbsoluteUri ,
                        1 ,
                        1 ,
                        8 ,
                        8 ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForHyperLinks = 1
                             THEN ISNULL(( MAX(p.Value) + 1 ) / ( DATEDIFF(DD,
                                                              MAX(hld.LastDiscovered),
                                                              GETDATE() + 1) ),
                                         0)
                             ELSE 0
                        END ,
						0 ,
                        0 ,
                        5 AS DiscoveryTypeID
              FROM      HyperLinks (NOLOCK) AS hl
                        INNER JOIN HyperLinks_Discoveries (NOLOCK) AS hld ON hl.ID = hld.HyperLinkID
                        LEFT OUTER JOIN DisallowedAbsoluteUris (NOLOCK) AS dau ON hl.AbsoluteUri = dau.AbsoluteUri
                        LEFT OUTER JOIN Files (NOLOCK) AS f ON hl.AbsoluteUri = f.AbsoluteUri
                        LEFT OUTER JOIN WebPages (NOLOCK) AS wp ON hl.AbsoluteUri = wp.AbsoluteUri
                        LEFT OUTER JOIN HyperLinks_Hosts_Discoveries (NOLOCK)
                        AS hlhd ON hl.ID = hlhd.HyperLinkID
                        LEFT OUTER JOIN Hosts_Discoveries (NOLOCK) AS hd ON hlhd.Host_DiscoveryID = hd.ID
                        LEFT OUTER JOIN Hosts (NOLOCK) AS h ON hd.HostID = h.ID
                        LEFT OUTER JOIN cfg.Priorities (NOLOCK) AS p ON h.Host = p.Host
              WHERE     @CreateCrawlRequestsFromDatabaseHyperLinks = 1
                        AND ( dau.ID IS NULL )
                        AND f.AbsoluteUri IS NULL
                        AND wp.AbsoluteUri IS NULL
                        --AND @@ROWCOUNT < @MaximumNumberOfCrawlRequestsToCreatePerBatch
              GROUP BY  hl.AbsoluteUri
              HAVING    MAX(hld.LastDiscovered) < ( SELECT  MAX(LastDiscovered)
                                                    FROM    HyperLinks_Discoveries
                                                  )
              ORDER BY  CASE WHEN @AssignCrawlRequestPrioritiesForWebPages = 1
                             THEN ISNULL(( MAX(p.Value) + 1 ) / ( DATEDIFF(DD,
                                                              MAX(hld.LastDiscovered),
                                                              GETDATE() + 1) ),
                                         0)
                        END DESC ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForWebPages = 0
                             THEN MAX(hld.LastDiscovered)
                        END ASC
              UNION
		      /**/ --WebPages
              SELECT TOP ( @MaximumNumberOfCrawlRequestsToCreatePerBatch )
                        wp.LastDiscovered ,
                        wp.AbsoluteUri ,
                        wp.AbsoluteUri ,
                        1 ,
                        1 ,
                        8 ,
                        8 ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForWebPages = 1
                             THEN ISNULL(( p.Value + 1 ) / ( DATEDIFF(DD,
                                                              wp.LastDiscovered,
                                                              GETDATE() + 1) ),
                                         0)
                             ELSE 0
                        END ,
                        0 ,
                        0 ,
                        7 AS DiscoveryTypeID
              FROM      WebPages (NOLOCK) AS wp
                        LEFT OUTER JOIN DisallowedAbsoluteUris (NOLOCK) AS dau ON wp.AbsoluteUri = dau.AbsoluteUri
                        LEFT OUTER JOIN WebPages_Hosts_Discoveries (NOLOCK) AS wphd ON wp.ID = wphd.WebPageID
                        LEFT OUTER JOIN Hosts_Discoveries (NOLOCK) AS hd ON wphd.Host_DiscoveryID = hd.ID
                        LEFT OUTER JOIN Hosts (NOLOCK) AS h ON hd.HostID = h.ID
                        LEFT OUTER JOIN cfg.Priorities (NOLOCK) AS p ON h.Host = p.Host
              WHERE     @CreateCrawlRequestsFromDatabaseWebPages = 1
                        AND hd.DiscoveryTypeID = 7
                        AND ( dau.ID IS NULL )
						--AND @@ROWCOUNT < @MaximumNumberOfCrawlRequestsToCreatePerBatch
              ORDER BY  CASE WHEN @AssignCrawlRequestPrioritiesForWebPages = 1
                             THEN ISNULL(( p.Value + 1 ) / ( DATEDIFF(DD,
                                                              wp.LastDiscovered,
                                                              GETDATE() + 1) ),
                                         0)
                        END DESC ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForWebPages = 0
                             THEN wp.LastDiscovered
                        END ASC ,
                        CrawlDepth DESC
              UNION
              /**/ --Files
              SELECT TOP ( @MaximumNumberOfCrawlRequestsToCreatePerBatch )
                        MAX(fd.LastDiscovered) ,
                        f.AbsoluteUri ,
                        f.AbsoluteUri ,
                        1 ,
                        1 ,
                        8 ,
                        8 ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForFiles = 1
                             THEN ISNULL(( MAX(p.Value) + 1 ) / ( DATEDIFF(DD,
                                                              MAX(fd.LastDiscovered),
                                                              GETDATE() + 1) ),
                                         0)
                             ELSE 0
                        END ,
                        0 ,
                        0 ,
                        4 AS DiscoveryTypeID
              FROM      Files (NOLOCK) AS f
                        INNER JOIN Files_Discoveries (NOLOCK) AS fd ON f.ID = fd.FileID
                        LEFT OUTER JOIN DisallowedAbsoluteUris (NOLOCK) AS dau ON f.AbsoluteUri = dau.AbsoluteUri
                        LEFT OUTER JOIN Files_Hosts_Discoveries (NOLOCK) AS fhd ON f.ID = fhd.FileID
                        LEFT OUTER JOIN Hosts_Discoveries (NOLOCK) AS hd ON fhd.Host_DiscoveryID = hd.ID
                        LEFT OUTER JOIN Hosts (NOLOCK) AS h ON hd.HostID = h.ID
                        LEFT OUTER JOIN cfg.Priorities (NOLOCK) AS p ON h.Host = p.Host
              WHERE     @CreateCrawlRequestsFromDatabaseFiles = 1
                        AND ( dau.ID IS NULL )
						--AND @@ROWCOUNT < @MaximumNumberOfCrawlRequestsToCreatePerBatch
              GROUP BY  f.AbsoluteUri
              HAVING    MAX(fd.LastDiscovered) < ( SELECT   MAX(LastDiscovered)
                                                   FROM     Files_Discoveries
                                                 )
              ORDER BY  CASE WHEN @AssignCrawlRequestPrioritiesForFiles = 1
                             THEN ISNULL(( MAX(p.Value) + 1 ) / ( DATEDIFF(DD,
                                                              MAX(fd.LastDiscovered),
                                                              GETDATE() + 1) ),
                                         0)
                        END DESC ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForFiles = 0
                             THEN MAX(fd.LastDiscovered)
                        END ASC
              --ORDER BY  MIN(fd.LastDiscovered)
              UNION
			  /**/ --Images
              SELECT TOP ( @MaximumNumberOfCrawlRequestsToCreatePerBatch )
                        MAX(id.LastDiscovered) ,
                        i.AbsoluteUri ,
                        i.AbsoluteUri ,
                        1 ,
                        1 ,
                        8 ,
                        8 ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForImages = 1
                             THEN ISNULL(( MAX(p.Value) + 1 ) / ( DATEDIFF(DD,
                                                              MAX(id.LastDiscovered),
                                                              GETDATE() + 1) ),
                                         0)
                             ELSE 0
                        END ,
                        0 ,
                        0 ,
                        6 AS DiscoveryTypeID
              FROM      Images (NOLOCK) AS i
                        INNER JOIN Images_Discoveries (NOLOCK) AS id ON i.ID = id.ImageID
                        LEFT OUTER JOIN DisallowedAbsoluteUris (NOLOCK) AS dau ON i.AbsoluteUri = dau.AbsoluteUri
                        LEFT OUTER JOIN Images_Hosts_Discoveries (NOLOCK) AS ihd ON i.ID = ihd.ImageID
                        LEFT OUTER JOIN Hosts_Discoveries (NOLOCK) AS hd ON ihd.Host_DiscoveryID = hd.ID
                        LEFT OUTER JOIN Hosts (NOLOCK) AS h ON hd.HostID = h.ID
                        LEFT OUTER JOIN cfg.Priorities (NOLOCK) AS p ON h.Host = p.Host
              WHERE     @CreateCrawlRequestsFromDatabaseImages = 1
                        AND ( dau.ID IS NULL )
						--AND @@ROWCOUNT < @MaximumNumberOfCrawlRequestsToCreatePerBatch
              GROUP BY  i.AbsoluteUri
              HAVING    MAX(id.LastDiscovered) < ( SELECT   MAX(LastDiscovered)
                                                   FROM     Images_Discoveries
                                                 )
              ORDER BY  CASE WHEN @AssignCrawlRequestPrioritiesForImages = 1
                             THEN ISNULL(( MAX(p.Value) + 1 ) / ( DATEDIFF(DD,
                                                              MAX(id.LastDiscovered),
                                                              GETDATE() + 1) ),
                                         0)
                        END DESC ,
                        CASE WHEN @AssignCrawlRequestPrioritiesForFiles = 0
                             THEN MAX(id.LastDiscovered)
                        END ASC
            ) AS CrawlRequests
    ORDER BY Priority DESC ,
            Created ASC

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Altering [dbo].[arachnode_omsp_WebPages_INSERT]'
GO
ALTER PROCEDURE [dbo].[arachnode_omsp_WebPages_INSERT]
    @WebPageAbsoluteUri VARCHAR(884),
    @ResponseHeaders VARCHAR(4000),
    @Source VARBINARY(MAX),
    @CodePage INT,
    @FullTextIndexType VARCHAR(20),
    @CrawlDepth INT,
    @ClassifyAbsoluteUri BIT,
    @WebPageID BIGINT OUTPUT
AS 
    SET NOCOUNT ON

    IF NOT EXISTS ( SELECT  AbsoluteUri
                    FROM    dbo.WebPages
                    WHERE   AbsoluteUri = @WebPageAbsoluteUri ) 
        BEGIN
            INSERT  WebPages
                    (
                      AbsoluteUri,
                      ResponseHeaders,
                      [Source],
                      CodePage,
                      FullTextIndexType,
                      CrawlDepth
                    )
            VALUES  (
                      @WebPageAbsoluteUri,
                      @ResponseHeaders,
                      @Source,
                      @CodePage,                      
                      @FullTextIndexType,
                      @CrawlDepth
                    )
        END
    ELSE 
        BEGIN
            IF EXISTS ( SELECT  ID
                        FROM    WebPages
                        WHERE   AbsoluteUri = @WebPageAbsoluteUri
                                AND CrawlDepth < @CrawlDepth ) 
                BEGIN
                    UPDATE  WebPages
                    SET     CrawlDepth = @CrawlDepth
                    WHERE   AbsoluteUri = @WebPageAbsoluteUri
                END

            IF EXISTS ( SELECT  ID
                        FROM    WebPages
                        WHERE   AbsoluteUri = @WebPageAbsoluteUri
                                AND ( [Source] <> @Source
                                      OR FullTextIndexType <> @FullTextIndexType
                                     ))
                BEGIN
                    UPDATE  WebPages
                    SET     LastDiscovered = GetDate(),
                            LastModified = GetDate(),
                            ResponseHeaders = @ResponseHeaders,
                            [Source] = @Source,
                            CodePage = @CodePage,
                            FullTextIndexType = @FullTextIndexType
                    WHERE   AbsoluteUri = @WebPageAbsoluteUri
                END
            ELSE 
                BEGIN
                    UPDATE  WebPages
                    SET     LastDiscovered = GetDate()
                    WHERE   AbsoluteUri = @WebPageAbsoluteUri
                END
        END

    SET @WebPageID = ( SELECT   ID
                       FROM     WebPages
                       WHERE    AbsoluteUri = @WebPageAbsoluteUri
                     )

    IF ( @ClassifyAbsoluteUri = 1 ) 
        BEGIN
	--scheme
            DECLARE @SchemeID INT,
                @Scheme_DiscoveryID INT
            EXEC dbo.arachnode_omsp_Schemes_INSERT @WebPageAbsoluteUri, 7,
                @SchemeID = @SchemeID OUTPUT,
                @Scheme_DiscoveryID = @Scheme_DiscoveryID OUTPUT

            EXEC dbo.arachnode_omsp_WebPages_Schemes_Discoveries_INSERT @WebPageID,
                @Scheme_DiscoveryID

	--extension, domain, host
            DECLARE @ExtensionID INT,
                @Extension_DiscoveryID INT
            EXEC dbo.arachnode_omsp_Extensions_INSERT @WebPageAbsoluteUri, 7,
                @ExtensionID = @ExtensionID OUTPUT,
                @Extension_DiscoveryID = @Extension_DiscoveryID OUTPUT

            DECLARE @DomainID INT,
                @Domain_DiscoveryID INT
            EXEC dbo.arachnode_omsp_Domains_INSERT @ExtensionID,
                @WebPageAbsoluteUri, 7, @DomainID = @DomainID OUTPUT,
                @Domain_DiscoveryID = @Domain_DiscoveryID OUTPUT

            DECLARE @Host_DiscoveryID INT
            EXEC dbo.arachnode_omsp_Hosts_INSERT @DomainID,
                @WebPageAbsoluteUri, 7, NULL,
                @Host_DiscoveryID = @Host_DiscoveryID OUTPUT

            EXEC dbo.arachnode_omsp_WebPages_Hosts_Discoveries_INSERT @WebPageID,
                @Host_DiscoveryID
        END

GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
PRINT N'Adding constraints to [dbo].[CrawlRequests]'
GO
ALTER TABLE [dbo].[CrawlRequests] ADD CONSTRAINT [CK_CrawlRequests_2] CHECK (([RestrictCrawlTo]<=(31)))
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [dbo].[CrawlRequests] ADD CONSTRAINT [CK_CrawlRequests_3] CHECK (([RestrictDiscoveriesTo]<=(31)))
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [dbo].[CrawlRequests] ADD CONSTRAINT [DF_CrawlRequests_RestrictCrawlTo] DEFAULT ((0)) FOR [RestrictCrawlTo]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
ALTER TABLE [dbo].[CrawlRequests] ADD CONSTRAINT [DF_CrawlRequests_RestrictDiscoveriesTo] DEFAULT ((0)) FOR [RestrictDiscoveriesTo]
GO
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT=0 BEGIN INSERT INTO #tmpErrors (Error) SELECT 1 BEGIN TRANSACTION END
GO
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT 'The database update succeeded'
COMMIT TRANSACTION
END
ELSE PRINT 'The database update failed'
GO
DROP TABLE #tmpErrors
GO

/*
Run this script on:

1-DF5689AFCABB4\SQL2005.arachnode.net    -  This database will be modified

to synchronize it with:

192.168.1.107.arachnode.net

You are recommended to back up your database before running this script

Script created by SQL Data Compare version 8.1.0 from Red Gate Software Ltd at 6/20/2010 2:11:31 PM

*/
		
SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON
GO
SET DATEFORMAT YMD
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRANSACTION
-- Pointer used for text / image updates. This might not be needed, but is declared here just in case
DECLARE @pv binary(16)

-- Drop constraints from [cfg].[CrawlActions]
ALTER TABLE [cfg].[CrawlActions] DROP CONSTRAINT [FK_CrawlActions_CrawlActionTypes]

-- Update 1 row in [cfg].[Version]
UPDATE [cfg].[Version] SET [Value]='2.5.0.0' WHERE [ID]=1

-- Add 1 row to [cfg].[Configuration]
INSERT INTO [cfg].[Configuration] ([ConfigurationTypeID], [Key], [Value], [Help]) VALUES (1, 'HttpWebRequestRetries', CAST(N'5' AS nvarchar(1)) COLLATE SQL_Latin1_General_CP1_CI_AS, 'The maximum number of retries that a Crawl will attempt should the WebPage not respond as a result of remote WebServer throttling.')

-- Add 1 row to [cfg].[CrawlActions]
SET IDENTITY_INSERT [cfg].[CrawlActions] ON
INSERT INTO [cfg].[CrawlActions] ([ID], [CrawlActionTypeID], [AssemblyName], [TypeName], [IsEnabled], [Order], [Settings]) VALUES (14, 3, 'Arachnode.SiteCrawler', 'Arachnode.SiteCrawler.Actions.Renderer', 1, 3, NULL)
SET IDENTITY_INSERT [cfg].[CrawlActions] OFF

-- Add constraints to [cfg].[CrawlActions]
ALTER TABLE [cfg].[CrawlActions] ADD CONSTRAINT [FK_CrawlActions_CrawlActionTypes] FOREIGN KEY ([CrawlActionTypeID]) REFERENCES [cfg].[CrawlActionTypes] ([ID]) ON DELETE CASCADE ON UPDATE CASCADE
COMMIT TRANSACTION
GO