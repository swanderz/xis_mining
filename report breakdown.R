#load required libraries, data, and created functions
library(dplyr)
library(tm)
library(tidyr)
library(SnowballC)
library(RWeka)


#set wd and paths and source functions
source("Functions.R")
setwd("/Users/andersswanson/Desktop/comment\ mining")
t1.report.path <-"data/t1 comments.csv"
t2.report.path <-"data/t2 comments.csv"

#load MB reports
t1.report <- GetReportsDFfromMBcsv(t1.report.path)
t2.report <- GetReportsDFfromMBcsv(t2.report.path)

#finding subset comments where student made improvement
by.cols <- c("Student.ID", "Last.Name", "First.Name",
             "Grade.Level", "Subject", "Teacher")
t12.report <- merge(t1.report, t2.report,
                    by = by.cols, suffixes = c(".t1", ".t2")) %>%
        mutate(class.growth = CriMean.t2 - CriMean.t1) %>%
        within(class.growth.quartile <- as.integer(cut(class.growth,
                                                              quantile(class.growth, probs=0:4/4,
                                                                       na.rm = TRUE),
                                                                include.lowest=TRUE)))
t12.report.byID <- t12.report %>% group_by(Student.ID) %>%
        summarize( class.growth.avg = mean(class.growth, na.rm = TRUE))
        

#finding student mean Cri score increase from T1 to T2
t1.grades.stats <- GetMeanBreakdownFromReport(t1.report)
t2.grades.stats <- GetMeanBreakdownFromReport(t2.report)

t12.grades.stats <- right_join(t1.grades.stats[[1]], t2.grades.stats[[1]],
                               by = "Student.ID") %>%
                        select(Student.ID, t1.avg = avg.x, t2.avg = avg.y) %>%
                        mutate(overall.growth = t2.avg - t1.avg)