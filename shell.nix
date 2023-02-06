{pkgs ? import <nixpkgs> {}}:
	
pkgs.mkShell {
	
	nativeBuildInputs = with pkgs; [
		lua5_3
		lua53Packages.moonscript
		lua53Packages.luasocket
		lua53Packages.luasec
		
		epubcheck
	];
}

