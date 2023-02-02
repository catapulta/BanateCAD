-- FileManager.lua
-- BanateCAD
-- Copyright (c) 2011  William Adams
--
require ("iuplua")
require ("lfs")

local class = require "pl.class"

class.FileManager()
function FileManager:_init(parms)
	parms = parms or {}		-- create object if user does not provide one

	self.NAME = parms.DefaultName
	self.fileopener = iup.filedlg{
		DIALOGTYPE="OPEN",
		EXTFILTER=parms.ExtFilter,
		TITLE="BanateCAD Files",
		}
	self.filesaver = iup.filedlg{
		DIALOGTYPE="SAVE",
		EXTFILTER=parms.ExtFilter,
		TITLE="BanateCAD Files",
		}
end

function FileManager.GetOpenFileName(self)
	iup.Popup(self.fileopener);

--	print(self.fileopener.VALUE);

	if self.fileopener.VALUE ~= nil then
		self.NAME = self.fileopener.VALUE
			-- Set the current directory to that of the file
		local success = lfs.chdir(self.fileopener.DIRECTORY)
print("do_file_open, success: ", success)

	end

	return self.fileopener.VALUE, self.fileopener.STATUS;
end

function FileManager.GetSaveFileName(self)
	self.filesaver.FILE = self.NAME;
	iup.Popup(self.filesaver);

	return self.filesaver.VALUE, self.filesaver.STATUS;
end

function FileManager.SetFileName(self, aname)
	self.NAME = aname;
end


return FileManager
