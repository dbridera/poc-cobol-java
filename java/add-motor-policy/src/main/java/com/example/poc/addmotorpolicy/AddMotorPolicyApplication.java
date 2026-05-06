package com.example.poc.addmotorpolicy;

import com.example.poc.addmotorpolicy.batch.BatchRunner;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.context.annotation.Bean;

import java.nio.file.Path;

/**
 * Entry point for the add-motor-policy batch translation of COBOL ADDMPOL.
 *
 * <p>Module zero deliberately does NOT bind to a database — golden-master
 * replay compares flat-file outputs to the COBOL run. JPA entities exist for
 * methodology completeness; persistence will be wired in module 1.
 */
@SpringBootApplication(exclude = {
        DataSourceAutoConfiguration.class,
        HibernateJpaAutoConfiguration.class
})
public class AddMotorPolicyApplication {

    public static void main(String[] args) {
        SpringApplication.run(AddMotorPolicyApplication.class, args);
    }

    @Bean
    CommandLineRunner runBatch(BatchRunner runner) {
        return args -> {
            // Args: [requests-file] [output-dir]   (defaults to CWD)
            Path requests = args.length >= 1 ? Path.of(args[0]) : Path.of("requests.dat");
            Path outDir   = args.length >= 2 ? Path.of(args[1]) : Path.of(".");
            int exit = runner.run(requests, outDir);
            // Match COBOL: 0 on normal completion (even with rejected records)
            System.exit(exit);
        };
    }
}
