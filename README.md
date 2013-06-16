Dreckig OS development has halted. It has been reincarnated as <a href="https://github.com/WizardOfHaas/d264b">d264b</a> in glorious 64 bit! 
If anyone wants to take the reigns and go down the road Dreckig OS was on let me know and I'll set you up. 

<pre>
     ________________________
=====|Dreckig OS User Manual|==
 ====|Alpha v0.007          |===
  ===|January 2013          |====
   ==|Dr. Sean Haas         |=====
     ------------------------



---What is Dreckig OS?---

Simply put, Dreckig OS is an ultra secure operating system based around the experimental megalithic kernel architecture.
In this archetecture, everything is inside the kernel, including user programs. This makes it run quickly and securely.


---The command line---

The command line in Dreckig OS is a mixture of native commands, lang commands and brainfuck(yes, really). Any time you are
able to give input you can hit the esc key to be dropped down to the command line.

Native commands:
       These are initiated with a one word command, and if any other data is needed the user is prompted.
Unprivleged: For everyone
       help  - terse help message
       re - reboot
       info - show some system info
       clear - clear screen
       log - super secure locking mechanism
       bf - the brainfuck vm
       hist - show command history
       lo -log out (quit also works)
       dte - the Dreckig Text Editor
       crypt - stenographic file system manager
       
Priveleged: For group 0
       dump - show contents at a given memory adress (dec)
       regs - show register contents
       ps - list proccesses
       kill - kill a proccess
       user - user control system
       hash - low level access to hashfs
       chr - chroot, change root directory

lang commands:
     These are run in the lang interpreter, usually more than one word long. I developed lang as a way to write simple scripts
     in Dreckig OS. One of it's biggest quirks is in it's variables, both of them. lang only has two variables, "var" and "bak"
Here is a quick list of more useful functions:
          some text > -- displays "some text"
	  prompt < -- get input from user qith prompt "prompt", stores in var
	  file name > -- display file "name"
	  run file -- runs lang file "file"
	  # cmd -- runs "cmd" as a native command
	  asr cmd -- run cmd as root

Brainfuck!:
	This is the fun part(or at least it was fun to write!). Either enter a piece of brainfuck code straight at the command
	line, or use the bf virtual machine to run an entire file of code. 
	The subtleties of this language will not be covered here.


---The file system---

    HashFS, the main file system used by Dreckig OS is based off of a simple hashing function. The idea being that the only 
data you need to access a file is it's name. When you want to access a file you provide it's name, the hash function is then 
applied to it, and the resulting hash points to where it is located on the disk. All files are up to 512 bytes in length. 
Since there are no file tables, you can't list the files on a disk. 
      This leads to the next file system, CryptFS, a cryptographical file
system. A CryptFS disk is first initialized to random data before it is used, then all data written to it is encrypted, making
it indistinguishable from the garbage on the disk. It uses the same scheme to order files as HashFS.


---Users---

	When Dreckig OS is booted up you will first be prompted for a username and password. The default priveleged acount is
root, it's password is root! Users are managed through the "user" command(only accessable while logged in as a user in group 0)
The user command has a few subcommands:
    list - list all user accounts
    add - make new user with specified name/password/group
    kill - remove user with specified name
    init - write a new initial user file to disk

    How useres are handled is in the file named "user" on the currently inserted disk. This file has an entry for every user 
with the user's name, a hash of their password, and their user group. User group 0 is the most priveleged, the user group is 
stored as a char. The init subcommand just writes a "user" file to disk with an entry for root.
       Now, how are user differant user's files kept seperate? Well, that is kinda a hack. As long as you are not in user group
0 then your user group id is prefixed to the name of every file you access. So if someone in group 1 tried to access the 
"user" file they would get "1user" instead. 
       When you log in the script "run" is run. It is written in lang, and is in plaintext. When you add a new user you should
write a quick run script for them so that is doesn't hit random junk and hang/crash. The usual group based access rescticions
apply, such that group 1 runs "1run".
       You can also access files in a specific user group by appending a username to the file name, such as:
       	   sean:run
       If sean is in user group 1 then this is the same as '1test'.


---Encryption---

	The crypt command handles CryptFS, the stenographic file system for Dreckig OS. Basically it is just used to format a
disk and turn encryption on and off. Subcommands:
     init - format a disk for CryptFS(Just full it with garbage)
     on - turn on encryption
     off - turn off encryption
     stat - show CryptFS status

     When you first log in encryption is turned off, so you need to turn it on if you want to use it. Also, don't run init on 
a boot disk, insert a new disk first, it reflects on your good judgement. If you have to run it on a boot disk then go ahead, 
it will just wipe *all* data on the disk, I mean **all**, every single sector. You can, however, turn encryption on for any 
disk, even the dook disk.


---Editing text---

	The text editor in Dreckig OS is DTE, the Dreckig Text Editor. It is almost useable! To make a file just type "dte" at 
the command line, it will then prompt for a file name. If the file is empty ti will drop out to a proptless mode and let you
type. When you are done just type "quit" on a line alone, it will then write the file to disk. 
      If the file has data in it(Which is always the case if the disk is formated for CryptFS.) then that data will be 
displayed. Then, you will be prompted for a line number. If you enter the line number(First one is 0!), then that line will be
displayed and you will be prompted for the data to replace it. When done with that line you will be given the line prompt
again. You can also enter commands here:
       q - quit without saving
       w - write file and quit
       t - display file
</pre>
