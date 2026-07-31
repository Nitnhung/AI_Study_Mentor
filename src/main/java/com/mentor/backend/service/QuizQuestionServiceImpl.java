package com.mentor.backend.service;

import com.mentor.backend.dto.QuizQuestionDTO;
import com.mentor.backend.entity.Question;
import com.mentor.backend.entity.Quiz;
import com.mentor.backend.entity.QuizQuestion;
import com.mentor.backend.repository.QuestionRepository;
import com.mentor.backend.repository.QuizQuestionRepository;
import com.mentor.backend.repository.QuizRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
// Đã xóa import UUID

@Service
public class QuizQuestionServiceImpl implements QuizQuestionService {

    @Autowired
    private QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Override
    public QuizQuestionDTO addQuestionToQuiz(QuizQuestionDTO dto) {
        // Đã xóa .toString()
        if (quizQuestionRepository.existsByQuiz_QuizIdAndQuestion_QuestionId(dto.getQuizId(), dto.getQuestionId())) {
            throw new RuntimeException("Câu hỏi này đã tồn tại trong Quiz!");
        }

        Quiz quiz = quizRepository.findById(dto.getQuizId()) // Đã xóa .toString()
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Quiz với ID: " + dto.getQuizId()));

        Question question = questionRepository.findById(dto.getQuestionId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy Question với ID: " + dto.getQuestionId()));

        QuizQuestion quizQuestion = new QuizQuestion();
        quizQuestion.setId(java.util.UUID.randomUUID().toString());
        quizQuestion.setQuiz(quiz);
        quizQuestion.setQuestion(question);
        quizQuestion.setIsCorrect(dto.getIsCorrect() != null ? dto.getIsCorrect() : false);

        QuizQuestion saved = quizQuestionRepository.save(quizQuestion);
        return mapToDTO(saved);
    }

    @Override
    public List<QuizQuestionDTO> getQuestionsByQuizId(String quizId) { // Sửa thành String
        List<QuizQuestion> quizQuestions = quizQuestionRepository.findByQuiz_QuizId(quizId); // Đã xóa .toString()
        return quizQuestions.stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    @Override
    public void removeQuestionFromQuiz(String id) {
        quizQuestionRepository.deleteById(id);
    }

    // Hàm tiện ích để chuyển đổi Entity -> DTO
    private QuizQuestionDTO mapToDTO(QuizQuestion entity) {
        return QuizQuestionDTO.builder()
                .id(entity.getId())
                .quizId(entity.getQuiz().getQuizId())
                .questionId(entity.getQuestion().getQuestionId())
                .isCorrect(entity.getIsCorrect())
                .build();
    }
}