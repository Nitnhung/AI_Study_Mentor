package com.brightpath.aimentor.config;

import com.brightpath.aimentor.entity.*;
import com.brightpath.aimentor.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Tạo dữ liệu mẫu khi khởi động lần đầu.
 * Mọi dữ liệu trong database đều do người dùng tạo ra khi dùng app
 * (đăng ký, hỏi AI, làm quiz...) — DataSeeder chỉ tạo demo ban đầu.
 */
@Component
public class DataSeeder implements CommandLineRunner {
    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);
    private final UserRepository userRepo;
    private final SubjectRepository subjectRepo;
    private final QuestionRepository questionRepo;
    private final AiAnswerRepository answerRepo;
    private final NotificationRepository notifRepo;
    private final LeaderboardRepository leaderRepo;
    private final ActivityLogRepository logRepo;
    private final PasswordEncoder encoder;

    public DataSeeder(UserRepository ur, SubjectRepository sr, QuestionRepository qr,
                      AiAnswerRepository ar, NotificationRepository nr,
                      LeaderboardRepository lr, ActivityLogRepository logr, PasswordEncoder enc) {
        this.userRepo=ur; this.subjectRepo=sr; this.questionRepo=qr; this.answerRepo=ar;
        this.notifRepo=nr; this.leaderRepo=lr; this.logRepo=logr; this.encoder=enc;
    }

    @Override
    public void run(String... args) {
        if (userRepo.count() > 0) {
            log.info("Database da co du lieu — bo qua seeding.");
            return;
        }

        log.info("Tao du lieu mau lan dau...");

        // Môn học
        subjectRepo.save(new Subject("s-math", "Toán", "Toán học các cấp"));
        subjectRepo.save(new Subject("s-eng", "Tiếng Anh", "Ngữ pháp, từ vựng"));
        subjectRepo.save(new Subject("s-phys", "Vật Lý", "Cơ, điện, quang"));
        subjectRepo.save(new Subject("s-chem", "Hoá Học", "Vô cơ, hữu cơ"));
        subjectRepo.save(new Subject("s-it", "CNTT", "Lập trình, mạng"));
        subjectRepo.save(new Subject("s-hist", "Lịch Sử", "VN và thế giới"));

        // Demo users — password "123456" được mã hoá đúng bởi BCrypt
        User demo = new User("u-demo", "admin@gmail.com", encoder.encode("123456"),
                "high_school", "step_by_step", "free", 1250);
        userRepo.save(demo);

        User user2 = new User("u-user2", "student@gmail.com", encoder.encode("123456"),
                "university", "detailed", "free", 800);
        userRepo.save(user2);

        User user3 = new User("u-user3", "hocsinh@gmail.com", encoder.encode("123456"),
                "middle_school", "short", "free", 450);
        userRepo.save(user3);

        // Câu hỏi + lời giải mẫu
        seedQuestion("q-001", "u-demo", "s-math", "Giải phương trình x² - 4 = 0",
            "{\"subject\":\"mathematics\",\"difficulty\":\"basic\",\"direct_answer\":\"x = 2 hoặc x = -2\",\"explanation\":\"Phương trình x² - 4 = 0 là dạng hiệu hai bình phương.\",\"steps\":[\"x² = 4\",\"x = ±√4\",\"x = ±2\"],\"formulas_or_concepts\":[\"a² - b² = (a-b)(a+b)\"],\"simplified_explanation\":\"Tìm số nhân chính nó ra 4.\",\"alternative_approaches\":[\"(x-2)(x+2) = 0\"],\"key_concepts_summary\":[\"Phương trình bậc hai\"],\"common_mistakes\":[\"Quên nghiệm âm x = -2\"],\"follow_up_questions\":[\"Giải x² - 9 = 0?\"]}");

        seedQuestion("q-002", "u-demo", "s-phys", "Định luật Newton thứ 2 là gì?",
            "{\"subject\":\"science\",\"difficulty\":\"basic\",\"direct_answer\":\"F = m × a\",\"explanation\":\"Gia tốc tỉ lệ thuận với lực, tỉ lệ nghịch với khối lượng.\",\"steps\":[\"F là lực (N)\",\"m là khối lượng (kg)\",\"a là gia tốc (m/s²)\"],\"formulas_or_concepts\":[\"F = ma\"],\"simplified_explanation\":\"Đẩy mạnh → nhanh hơn. Nặng hơn → chậm hơn.\",\"alternative_approaches\":[],\"key_concepts_summary\":[\"Lực, khối lượng, gia tốc\"],\"common_mistakes\":[\"Nhầm đơn vị\"],\"follow_up_questions\":[\"Tính a khi F=10N, m=2kg?\"]}");

        seedQuestion("q-003", "u-demo", "s-it", "JWT là gì?",
            "{\"subject\":\"programming\",\"difficulty\":\"intermediate\",\"direct_answer\":\"JWT là token mã hoá dùng xác thực người dùng.\",\"explanation\":\"JSON Web Token gồm Header, Payload, Signature.\",\"steps\":[\"User gửi credentials\",\"Server tạo JWT\",\"Client gửi kèm mỗi request\",\"Server xác thực\"],\"formulas_or_concepts\":[\"JWT = Header.Payload.Signature\"],\"simplified_explanation\":\"Giống vé xe buýt — mua 1 lần, đi nhiều chuyến.\",\"alternative_approaches\":[\"Session-based auth\"],\"key_concepts_summary\":[\"Stateless auth\"],\"common_mistakes\":[\"Lưu token không an toàn\"],\"follow_up_questions\":[\"Refresh token là gì?\"]}");

        // Activity logs
        logRepo.save(new ActivityLog("u-demo", "Asked_Question"));
        logRepo.save(new ActivityLog("u-demo", "Asked_Question"));
        logRepo.save(new ActivityLog("u-demo", "Completed_Quiz"));

        // Notifications
        notifRepo.save(new Notification("n-1", "u-demo", "Chào mừng đến AI Study Mentor!", "Motivation"));
        notifRepo.save(new Notification("n-2", "u-demo", "Bạn đạt 1000 XP!", "Motivation"));
        notifRepo.save(new Notification("n-3", "u-demo", "Quiz mới đã sẵn sàng", "Alert"));

        // Leaderboard
        leaderRepo.save(new Leaderboard("lb-1", "u-demo", 1, 1250));
        leaderRepo.save(new Leaderboard("lb-2", "u-user2", 2, 800));
        leaderRepo.save(new Leaderboard("lb-3", "u-user3", 3, 450));

        log.info("Du lieu mau da duoc tao thanh cong!");
    }

    private void seedQuestion(String qId, String userId, String subjectId, String text, String answerJson) {
        Question q = new Question();
        q.setQuestionId(qId); q.setUserId(userId); q.setSubjectId(subjectId);
        q.setQuestionText(text); q.setQuestionHash("hash-" + qId); q.setStatus("Resolved");
        questionRepo.save(q);

        AiAnswer a = new AiAnswer();
        a.setAnswerId("a-" + qId); a.setQuestionId(qId); a.setContentData(answerJson);
        a.setIsCachedResponse(false); a.setApiTokensUsed(150); a.setAiModelVersion("gemini-2.0-flash");
        answerRepo.save(a);
    }
}
