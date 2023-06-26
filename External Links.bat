mkdir Externals

cd Externals

mklink /j DUnitX %1"\DUnitX"
mklink /j FastMM5 %1"\FastMM5"
mklink /j Translucent %1"\Translucent"

cd..
