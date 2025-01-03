function Get-NewPassword ([int32]$len)

{

if (!$len) {[int32]$len = 30} #length of 30 should give us > 128bit password entropy - see http://www.ask.com/wiki/Password_strength?qsrc=3044

[string]$charset = 'abcdefghkmnoprstuvwxyzABCDEFGHKLMNOPRSTUVWXYZ1234567890!@#$%^&*()_+[{]}/\|~'

$randchar = 1..$len | ForEach-Object { Get-Random -Maximum $charset.length }

$ofs="" #$ofs = output field separator

[string]$charset[$randchar] #if we don't use [string] then there is a CR between chars

[string]$charset[$randchar] | CLIP #this puts the password in the clipboard, ready for use

}

Get-NewPassword (20)