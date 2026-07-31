package com.mentor.backend.service;

import com.mentor.backend.dto.QuestionDTO;
import com.mentor.backend.entity.Question;
import com.mentor.backend.entity.Subject;
import com.mentor.backend.entity.User;
import com.mentor.backend.repository.QuestionRepository;
import com.mentor.backend.repository.SubjectRepository;
import com.mentor.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
// Đã xóa import UUID

@Service
public class QuestionService {

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    // Helper method: Chuyển từ Entity sang DTO để trả về cho Client
    private QuestionDTO mapToDTO(Question question) {
        return new QuestionDTO(
                question.getQuestionId(),
                question.getUser().getUserId(), // Đã xóa .toString() vì giờ là String
                question.getSubject().getSubjectId(),
                question.getQuestionText(),
                question.getImageUrl(),

                question.getOptionA(),
                question.getOptionB(),
                question.getOptionC(),
                question.getOptionD(),
                question.getCorrectAnswer(),

                question.getCreatedAt()
        );
    }

    // 1. CREATE - Tạo câu hỏi mới
    public QuestionDTO createQuestion(QuestionDTO questionDTO) {
        User user = userRepository.findById(questionDTO.getUserId()) // Đã xóa UUID.fromString()
                .orElseThrow(() -> new RuntimeException("Không tìm thấy User với ID: " + questionDTO.getUserId()));

        Subject subject = subjectRepository.findById(questionDTO.getSubjectId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Subject với ID: " + questionDTO.getSubjectId()));

        Question question = new Question();
        question.setQuestionId(java.util.UUID.randomUUID().toString());
        question.setQuestionText(questionDTO.getQuestionText());
        question.setImageUrl(questionDTO.getImageUrl());
        question.setUser(user);
        question.setSubject(subject);

        Question savedQuestion = questionRepository.save(question);
        return mapToDTO(savedQuestion);
    }

    // 2. READ - Lấy tất cả câu hỏi
    public List<QuestionDTO> getAllQuestions() {
        return questionRepository.findAll()
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    // 3. READ - Lấy câu hỏi theo ID
    public QuestionDTO getQuestionById(String id) {
        Question question = questionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Câu hỏi với ID: " + id));
        return mapToDTO(question);
    }

    // 4. UPDATE - Cập nhật câu hỏi
    public QuestionDTO updateQuestion(String id, QuestionDTO questionDetails) {
        Question question = questionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Câu hỏi với ID: " + id));

        if (questionDetails.getQuestionText() != null) {
            question.setQuestionText(questionDetails.getQuestionText());
        }
        if (questionDetails.getImageUrl() != null) {
            question.setImageUrl(questionDetails.getImageUrl());
        }

        if (questionDetails.getOptionA() != null) question.setOptionA(questionDetails.getOptionA());
        if (questionDetails.getOptionB() != null) question.setOptionB(questionDetails.getOptionB());
        if (questionDetails.getOptionC() != null) question.setOptionC(questionDetails.getOptionC());
        if (questionDetails.getOptionD() != null) question.setOptionD(questionDetails.getOptionD());
        if (questionDetails.getCorrectAnswer() != null) question.setCorrectAnswer(questionDetails.getCorrectAnswer());

        Question updatedQuestion = questionRepository.save(question);
        return mapToDTO(updatedQuestion);
    }

    // 5. DELETE - Xóa câu hỏi
    public void deleteQuestion(String id) {
        Question question = questionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Câu hỏi với ID: " + id));
        questionRepository.delete(question);
    }

    // 6. READ - Lấy danh sách câu hỏi theo ID môn học
    public List<QuestionDTO> getQuestionsBySubjectId(String subjectId) {
        // Đã xóa UUID.fromString()
        List<Question> questions = questionRepository.findBySubject_SubjectId(subjectId);

        return questions.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }
}