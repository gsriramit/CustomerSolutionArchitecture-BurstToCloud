 USE [svc-Todo-primaryDb]
GO

/****** Object: Table [dbo].[Todo] Script Date: 26-03-2023 15:49:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Todo] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [Description] NVARCHAR (MAX) NULL,
    [CreatedDate] DATETIME2 (7)  NOT NULL
); 