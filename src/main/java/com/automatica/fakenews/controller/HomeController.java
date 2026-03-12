package com.automatica.fakenews.controller;

import com.automatica.fakenews.dto.ReportForm;
import com.automatica.fakenews.model.FakeNewsReport;
import com.automatica.fakenews.service.FakeNewsReportService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
public class HomeController {

    private static final Logger logger = LoggerFactory.getLogger(HomeController.class);
    private final FakeNewsReportService reportService;

    public HomeController(FakeNewsReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/")
    public String home(Model model) {
        List<FakeNewsReport> reports = reportService.getPublicReports();
        logger.info("Serving home page with {} public reports", reports.size());
        model.addAttribute("reports", reports);
        return "index";
    }

    @GetMapping("/reports")
    public String reports(Model model) {
        List<FakeNewsReport> reports = reportService.getPublicReports();
        logger.info("Serving reports page with {} public reports", reports.size());
        model.addAttribute("reports", reports);
        return "reports";
    }

    @GetMapping("/report")
    public String showReportForm(Model model) {
        model.addAttribute("reportForm", new ReportForm());
        return "report-form";
    }

    @PostMapping("/report")
    public String submitReport(@Valid @ModelAttribute("reportForm") ReportForm reportForm,
                               BindingResult bindingResult,
                               RedirectAttributes redirectAttributes,
                               Model model) {
        if (bindingResult.hasErrors()) {
            logger.warn("Report submission validation failed for news source '{}'", reportForm.getNewsSource());
            return "report-form";
        }

        FakeNewsReport report = new FakeNewsReport();
        report.setNewsSource(reportForm.getNewsSource());
        report.setUrl(reportForm.getUrl());
        report.setCategory(reportForm.getCategory());
        report.setDescription(reportForm.getDescription());

        reportService.saveReport(report);
        logger.info("New report submitted for source '{}'", report.getNewsSource());

        redirectAttributes.addFlashAttribute("successMessage",
            "Thank you! Your report has been submitted and is pending approval.");
        
        return "redirect:/";
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }
}
