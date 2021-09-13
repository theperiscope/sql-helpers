BEGIN TRY

	BEGIN TRANSACTION

	IF 1 = 1
	BEGIN
		RAISERROR (N'Some validation failed', 11 /* Severity */, 1 /* State */);
	END

	COMMIT TRANSACTION

END TRY
BEGIN CATCH

	IF ERROR_NUMBER() IS NULL
		RETURN

	DECLARE @ErrorMessage   NVARCHAR(4000),
			@ErrorNumber	INT,
			@ErrorSeverity  INT,
			@ErrorState		INT,
			@ErrorLine		INT,
			@ErrorProcedure NVARCHAR(200)

	SELECT @ErrorNumber = ERROR_NUMBER(),
		   @ErrorSeverity = ERROR_SEVERITY(),
		   @ErrorState = ERROR_STATE(),
		   @ErrorLine = ERROR_LINE(),
		   @ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-');
	SELECT @ErrorMessage = ERROR_MESSAGE()

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	DECLARE @printMsg NVARCHAR(MAX) =
		N'Error ' + CAST(@ErrorNumber AS VARCHAR(10)) +
		', Level ' + CAST(@ErrorSeverity AS VARCHAR(10)) +
		', State ' + CAST(@ErrorState AS VARCHAR(10)) +
		', Procedure ' + @ErrorProcedure +
		', Line ' + CAST(@ErrorLine AS VARCHAR(10)) +
		', Message: ' + @ErrorMessage

	PRINT @printMsg

	RAISERROR (N'Error %d, Level %d, State %d, Procedure %s, Line %d, Message: %s', @ErrorSeverity, 1, @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage)

END CATCH