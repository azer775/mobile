package org.example.backend.controllers;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class DownloadPageController {

    @GetMapping({"/download", "/download/"})
    public String redirectToDownloadPage() {
        return "redirect:/download/index.html";
    }
}
