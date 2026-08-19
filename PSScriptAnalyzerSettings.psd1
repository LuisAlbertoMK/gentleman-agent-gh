@{
    # PSScriptAnalyzer Settings for gentleman-agent-gh
    # Rules to include (security + correctness + best practices)
    IncludeRules = @(
        # Security rules
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingUsernameAuthentically'
        'PSAvoidUsingWriteHost'
        
        # Correctness rules
        'PSUseApprovedVerbs'
        'PSUseSingularNouns'
        'PSUseBOMForUnicodeEncodedFile'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingWMICmdlet'
        
        # Best practices
        'PSUseShouldProcessForStateChangingFunctions'
        'PSShouldProcess'
        'PSReviewUnusedParameter'
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSReviewUnusedVariable'
    )
    
    # Rules to exclude (style rules that are too noisy for this codebase)
    ExcludeRules = @(
        'PSAvoidUsingPositionalParameters'
        'PSAvoidDefaultValueSwitchStatement'
        'PSUseConsistentWhitespace'
        'PSUseConsistentIndentation'
        'PSAvoidGlobalVars'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSUseParamBlockOnly'
        'PSUsePipeline'
    )
    
    IncludeDefaultRules = $false
}