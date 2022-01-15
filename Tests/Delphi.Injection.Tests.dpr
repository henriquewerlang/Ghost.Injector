program Delphi.Injection.Tests;

{$STRONGLINKTYPES ON}

uses
  FastMM5,
  DUnitX.MemoryLeakMonitor.FastMM5,
  TestInsight.DUnitX,
  DUnitX.TestFramework,
  Delphi.Injection in '..\Delphi.Injection.pas',
  Delphi.Injection.Test in 'Delphi.Injection.Test.pas';

begin
  TestInsight.DUnitX.RunRegisteredTests;
end.
