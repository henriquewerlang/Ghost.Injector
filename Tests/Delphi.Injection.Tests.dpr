program Delphi.Injection.Tests;

{$STRONGLINKTYPES ON}

uses
  FastMM5,
  DUnitX.MemoryLeakMonitor.FastMM5,
  TestInsight.DUnitX,
  DUnitX.TestFramework,
  System.Rtti,
  Delphi.Injection in '..\Delphi.Injection.pas',
  Delphi.Injection.Test in 'Delphi.Injection.Test.pas';

begin
  FastMM_EnterDebugMode;

  FastMM_OutputDebugStringEvents := [];
  FastMM_LogToFileEvents := [mmetUnexpectedMemoryLeakSummary, mmetUnexpectedMemoryLeakDetail];
  FastMM_MessageBoxEvents := [mmetDebugBlockDoubleFree, mmetVirtualMethodCallOnFreedObject];

  FastMM_DeleteEventLogFile;

  var Context := TRttiContext.Create;

  for var RttiType in Context.GetTypes do
  begin
    RttiType.GetMethods;

    RttiType.QualifiedName;
  end;

  Context.Free;

  TestInsight.DUnitX.RunRegisteredTests;
end.
