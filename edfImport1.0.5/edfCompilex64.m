%%  edfImport library v1.0 
%  Alexander Pastukhov 
%  kobi.nat.uni-magdeburg.de/sasha
%  email: pastukhov.alexander@gmail.com
%
%  edfCompile
%  OS-sensitive script for library compilation. Plese, modify paths  to
%  suite your environment. 

%% Compiles edfImport library
if (ispc())
  %% Windows
  edfapiIncludesFolder= 'C:\Program Files\SR Research\EyeLink\EDF_Access_API\lib\win64\header';
  edfapiLibraryFolder= 'C:\Program Files (x86)\SR Research\EyeLink\EDF_Access_API\lib\';
  eval(sprintf('mex -g -largeArrayDims -I''%s'' edfMexImport.cpp EDFFILE2.cpp ''%s/edfapi64.lib''', edfapiIncludesFolder, edfapiLibraryFolder));
  eval(sprintf('mex -g -largeArrayDims -I''%s'' edfAPIbugMEX.cpp ''%s/edfapi64.lib''', edfapiIncludesFolder, edfapiLibraryFolder));
%   eval(sprintf('mex -I''%s'' edfMexImport.cpp EDFFILE2.cpp ''%s/edfapi64.lib''', edfapiIncludesFolder, edfapiLibraryFolder));
%   eval(sprintf('mex -I''%s'' edfAPIbugMEX.cpp ''%s/edfapi64.lib''', edfapiIncludesFolder, edfapiLibraryFolder));
elseif (isunix())
  %% Linux/Unix
  mex edfMexImport.cpp EDFFile2.cpp -ledfapi -lm -lz -lrt; 
elseif (ismac())
  %% Mac OS
  mex edfMexImport.cpp EDFFILE2.cpp -ledfapi; 
else
  fprintf('Sorry, have no clue what OS you''ve got!\n');
end;
  
fprintf('Library was compiled successfully!\n');