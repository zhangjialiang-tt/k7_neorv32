# FILEPATH: /C:/100-Working/102-Working-Prj/Embedded_Group_Repositories/AlgorithmModule/ghe/sim/test/simulation.tcl

# This procedure returns the format string based on the number of bytes and sign.
#
# Arguments:
#   - numberofbytes: The number of bytes.
#   - sign: The sign of the value ("signed" or "unsigned").
#
# Returns:
#   The format string corresponding to the number of bytes and sign.
proc get_format_string {numberofbytes sign} {
    switch $sign {
        "signed" {
            switch $numberofbytes {
                1 {set formatString "c" }
                2 {set formatString "s" }
                4 {set formatString "i" }
                8 {set formatString "w" }
                default {}
            }
        }
        "unsigned" {
            switch $numberofbytes {
                1 {set formatString "C" }
                2 {set formatString "S" }
                4 {set formatString "I" }
                8 {set formatString "W" }
                default {}
            }
        }
        default {}
    }
    return $formatString
}

# FILEPATH: /C:/100-Working/102-Working-Prj/Embedded_Group_Repositories/AlgorithmModule/ghe/sim/test/simulation.tcl

# This procedure converts data from a source file to raw binary format and writes it to a target file.
#
# Parameters:
#   - infile: The path of the source file.
#   - outfile: The path of the target file.
#   - formatString: The format string used to convert the data to binary.
#
# Returns: None
proc dat2raw {infile outfile formatString} {
    set infile [open $infile r]

    # Open the target file (binary data file) for writing
    set outfile [open $outfile wb]

    # Read each line of data from the source file
    while {[gets $infile line] >= 0} {
        # Convert the read string to an integer
        set decValue [expr {int($line)}]

        # Convert the decimal integer to a binary string in little-endian format
        binary scan [binary format $formatString $decValue] c* binaryData

        # Write the binary data
        puts -nonewline $outfile [binary format c* $binaryData]
    }

    # Close the files
    close $infile
    close $outfile
}

# 读取本地的二进制raw文件，并进行比较
proc raw_compare {raw_file_1 raw_file_2} {
    set raw_file_1 [open $raw_file_1 rb]
    set raw_file_2 [open $raw_file_2 rb]

    # 读取第一个文件的内容
    set content1 [read $raw_file_1]
    # 读取第二个文件的内容
    set content2 [read $raw_file_2]
    close $raw_file_1


    close $raw_file_2
    if {$content1 eq $content2} {
    puts "The files are identical."
    } else {
    puts "The files are different."
    }
}
proc get_file_list {dir} {
    set file_list [glob -nocomplain -directory $dir -type f *]
    return $file_list
}
proc check_raw {dir} {
    set file_list [get_file_list $dir]
    foreach file $file_list {
        if {[string last ".raw" $file] != -1} {
            return 1
        }
    }
    return 0
}

proc delete_raw_file {dir} {
    set file_list [get_file_list $dir]
    foreach file $file_list {
        if {[string last ".raw" $file] != -1} {
            file delete $file
        }
    }
}
proc txt2raw {dir formatString} {
    puts "check if there is raw file"
    set file_list [get_file_list $dir]
    foreach file $file_list {
        if {[string last ".raw" $file] != -1} {
            file delete $file
            puts "delete raw file: $file"
        }
        # 处理$file变量，将后缀的txt修改为raw文件
        set last_three_chars [string range $file end-5 end]
        if {$last_three_chars eq "result"} {
            set file2 [string replace $file end-5 end "raw"]
                dat2raw $file $file2 $formatString
                # puts "dat: $file2"
           }
    }
}

set numberofbytes 2
set sign "signed"
set formatString [get_format_string $numberofbytes $sign]

txt2raw ../output $formatString