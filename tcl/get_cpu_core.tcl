if {[info exists ::env(NUMBER_OF_PROCESSORS)]} {
    set num_processors $::env(NUMBER_OF_PROCESSORS)
    puts "CPU Cores: $num_processors"
} else {
    puts "WARNING: Could not determine number of CPU cores."
}