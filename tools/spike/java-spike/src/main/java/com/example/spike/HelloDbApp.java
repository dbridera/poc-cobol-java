package com.example.spike;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import java.io.BufferedWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;

@SpringBootApplication
public class HelloDbApp {

    public static void main(String[] args) {
        SpringApplication.run(HelloDbApp.class, args);
    }

    @Bean
    @Transactional
    CommandLineRunner runner(WidgetRepository repo) {
        return args -> {
            repo.deleteAllInBatch();
            repo.save(new Widget(1L, "first",  "2026-01-01 00:00:00"));
            repo.save(new Widget(2L, "second", "2026-01-01 00:00:00"));

            List<Widget> all = repo.findAll();
            all.sort(Comparator.comparing(Widget::getId));

            Path dumpPath = Path.of(args.length > 0 ? args[0] : "out/widget.txt");
            Files.createDirectories(dumpPath.getParent());
            try (BufferedWriter w = Files.newBufferedWriter(dumpPath)) {
                for (Widget x : all) {
                    w.write(x.getId() + "|" + x.getName() + "|" + x.getTs());
                    w.write('\n');
                }
            }

            System.out.println("WIDGETS INSERTED OK");
        };
    }
}

@Entity
@Table(name = "WIDGET")
class Widget {
    @Id
    private Long id;
    @Column(name = "name")
    private String name;
    @Column(name = "ts")
    private String ts;

    protected Widget() {}

    Widget(Long id, String name, String ts) {
        this.id = id;
        this.name = name;
        this.ts = ts;
    }

    Long getId()     { return id; }
    String getName() { return name; }
    String getTs()   { return ts; }
}

interface WidgetRepository extends JpaRepository<Widget, Long> {}
