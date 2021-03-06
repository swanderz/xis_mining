setwd("/Users/andersswanson/Desktop/comment\ mining")
source("Functions.R")


# Admin Plus --------------------------------------------------------------


#load Admin Plus Datebase
xis.db <- GetStudentDBfromAPxlsx("data/xis db.xlsx")


# ManageBac ---------------------------------------------------------------


#load MB reports
t1.report <- GetReportsDFfromMBcsv("data/t1 comments.csv")
t2.report <- GetReportsDFfromMBcsv("data/t2 comments.csv")
t3.report <- GetReportsDFfromMBcsv("data/t3 comments.csv")

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
        summarize( avg.CriMean.t1 = mean(CriMean.t1, na.rm = TRUE),
                   avg.CriMean.t2 = mean(CriMean.t2, na.rm = TRUE),
                   growth.avg = mean(class.growth, na.rm = TRUE)) %>%
        within(growth.quartile <- as.integer(cut(growth.avg,
                                                 quantile(growth.avg, probs=0:4/4,
                                                          na.rm = TRUE),
                                                 include.lowest=TRUE)))

# MAP databases (Fall & Spring) ------------------------------------------------


#Load MAP score databases
MAP.testdate <- c("2015Fall", "2016Spring")
MAP.path <- paste("data/", MAP.testdate,".Map.Results.csv", sep = "")
MAP <- lapply(MAP.path, GetMAPbyID)

#merge fall and spring map databases to have the following
MAP.DIFF <- merge(MAP[1], MAP[2],
                  by = "Student.ID", suffixes = c(".FALL", ".SPRING")) %>%
        mutate(Lang.RITGrowth = Lang.RITScore.SPRING - Lang.RITScore.FALL) %>%
        mutate(Read.RITGrowth = Read.RITScore.SPRING - Read.RITScore.FALL) %>%
        mutate(Math.RITGrowth = Math.RITScore.SPRING - Math.RITScore.FALL) %>%
        select(Student.ID, starts_with("Math."), starts_with("Read."),starts_with("Lang."))



#concat ManageBac df with AdminPlus df
MB.AP.db <- inner_join(xis.db, t12.report.byID, by="Student.ID")


#joining!
MB.MAP.db <- inner_join(t12.report.byID, MAP.DIFF, by="Student.ID")
sec.y <- 60*60*24*365
all <- right_join(xis.db, MB.MAP.db, by="Student.ID") %>%
        mutate(
                Age = as.period(interval(start = BIRTH.DATE,
                                         end = today())),
                Years.at.XIS = as.period(interval(start = ENTRY.DAY.1,
                                                  end = today()))) %>%
        mutate_each(funs(as.numeric), GRADE.LEVEL) %>%
        mutate_each(funs(as.numeric), starts_with("Math")) %>%
        mutate_each(funs(as.numeric), starts_with("Lang")) %>%
        mutate_each(funs(as.numeric), starts_with("Read")) %>%
        mutate(career_pct = 100 * Years.at.XIS / (Age - 4),
               Years.XIS.int = period_to_seconds(Years.at.XIS)/sec.y)










